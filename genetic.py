import random

def generate_initial_population(pop_size, days, teams):
    population = []
    for _ in range(pop_size):
        individual = []
        for day in range(1, days + 1):
            matches_for_day = []
            available_teams = list(teams)
            while len(available_teams) > 1:
                home_team = random.choice(available_teams)
                available_teams.remove(home_team)
                away_team = random.choice(available_teams)
                available_teams.remove(away_team)
                matches_for_day.append((day, home_team, away_team))
            individual.extend(matches_for_day)
        population.append(individual)
    return population

def fitness(schedule):
    score = 0
    played_home_games = set()
    
    for day, home, away in schedule:
        if (home, away) in played_home_games:
            score -= 10
        else:
            played_home_games.add((home, away))
        
        if day-1 >= len(avail) or home-1 >= len(avail[0]) or away-1 >= len(avail[0]):
            continue
        
        if avail[day-1][home-1] == 2 or avail[day-1][home-1] == 0 or avail[day-1][away-1] == 2:
            score -= 10
    
    for day in range(1, len(avail)+1):
        teams_playing = set()
        for d, home, away in schedule:
            if d == day:
                if home in teams_playing or away in teams_playing:
                    score -= 10
                teams_playing.add(home)
                teams_playing.add(away)
    
    return score

def selection(population, fitnesses):
    fitnesses = [f + abs(min(fitnesses)) + 1 for f in fitnesses]  # Normalize fitness values to be positive
    selected = random.choices(population, weights=fitnesses, k=len(population)//2)
    return selected

def crossover(parent1, parent2):
    cut = random.randint(1, len(parent1)-1)
    child1 = parent1[:cut] + parent2[cut:]
    child2 = parent2[:cut] + parent1[cut:]
    return child1, child2

def mutate(individual, mutation_rate=0.01):
    for i in range(len(individual)):
        if random.random() < mutation_rate:
            swap_with = random.randint(0, len(individual)-1)
            individual[i], individual[swap_with] = individual[swap_with], individual[i]
    return individual

def genetic_algorithm(pop_size, generations, days, teams):
    population = generate_initial_population(pop_size, days, teams)
    for generation in range(generations):
        fitnesses = [fitness(ind) for ind in population]
        
        new_population = []
        selected = selection(population, fitnesses)
        
        while len(new_population) < pop_size:
            parent1, parent2 = random.sample(selected, 2)
            child1, child2 = crossover(parent1, parent2)
            new_population.append(mutate(child1))
            new_population.append(mutate(child2))
        
        population = new_population
        print(f"Generation {generation} Best Fitness: {max(fitnesses)}")
    
    best_schedule = max(population, key=fitness)
    return best_schedule

# Define the days and teams
days = 9
teams = list(range(1, 4))

# Define the availability data (this should be your actual data)
avail = [
    [1, 2, 0], [1, 2, 0], [1, 2, 0], 
    [2, 0, 1], [2, 0, 1], [2, 0, 1], 
    [0, 1, 2], [0, 1, 2], [0, 1, 2]
]

# Run the genetic algorithm
best_schedule = genetic_algorithm(pop_size=100, generations=500, days=days, teams=teams)

# Output the best schedule
for match in best_schedule:
    print(f"Day {match[0]}: Home Team {match[1]} vs Away Team {match[2]}")
