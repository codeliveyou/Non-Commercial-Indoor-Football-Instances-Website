from gurobipy import Model, GRB, quicksum

# Data
days = 9
teams = 3
Rmax = 3
m = 2

avail = [
    [1, 2, 0], [1, 2, 0], [1, 2, 0],
    [2, 0, 1], [2, 0, 1], [2, 0, 1],
    [0, 1, 2], [0, 1, 2], [0, 1, 2]
]

# Create the model
model = Model("match_scheduling")

# Decision variables
x = model.addVars(days, teams, teams, vtype=GRB.BINARY, name="x")

# Objective function
model.setObjective(quicksum(x[d,h,a] for d in range(days) for h in range(teams) for a in range(teams)), GRB.MAXIMIZE)

# Constraints
# C1: Each team plays a home game against each other team at most once
for h in range(teams):
    for a in range(teams):
        if h != a:
            model.addConstr(quicksum(x[d,h,a] for d in range(days)) <= 1)
        else:
            model.addConstr(quicksum(x[d,h,a] for d in range(days)) == 0)

# C2: Home team availability
for d in range(days):
    for h in range(teams):
        if avail[d][h] == 2 or avail[d][h] == 0:
            for a in range(teams):
                x[d,h,a].UB = 0

# C3: Away team unavailability
for d in range(days):
    for a in range(teams):
        if avail[d][a] == 2:
            for h in range(teams):
                x[d,h,a].UB = 0

# C4: Each team plays at most one game per time slot
for d in range(days):
    for t in range(teams):
        model.addConstr(quicksum(x[d,t,a] for a in range(teams) if t != a) + quicksum(x[d,h,t] for h in range(teams) if h != t) <= 1)

# C5: Each team plays at most 2 games in a period of Rmax time slots
for t in range(teams):
    for d in range(days - Rmax + 1):
        model.addConstr(quicksum(x[dd,t,a] + x[dd,h,t] for dd in range(d, d + Rmax) for a in range(teams) if t != a for h in range(teams) if h != t) <= 2)

# C6: At least m time slots between two games with the same pair of teams
for h in range(teams):
    for a in range(teams):
        if h != a:
            for d1 in range(days - m):
                for d2 in range(d1 + 1, min(d1 + m, days)):
                    model.addConstr(x[d1,h,a] + x[d2,h,a] <= 1)

# Optimize the model
model.optimize()

# Output the schedule
for d in range(days):
    for h in range(teams):
        for a in range(teams):
            if x[d,h,a].X > 0.5:
                print(f"Day {d+1}: Home Team {h+1} vs Away Team {a+1}")
