import os

def read_input_file(filename):
    with open(filename, 'r') as file:
        lines = file.readlines()
        total_days = int(lines[0])
        total_teams = int(lines[1])
        availabilities = [[int(val) for val in line.split()] for line in lines[2:]]
    return total_days, total_teams, availabilities

def generate_prolog_file(total_days, total_teams, availabilities, filename):
    name = filename.split(".")[0]
    output_dir = "PrologFacts"
    os.makedirs(output_dir, exist_ok=True)
    with open(os.path.join(output_dir, f"{name}.pl"), 'w') as file:
    # with open(f"{name}.pl", 'w') as file:
        for day in range(1, total_days + 1):
            file.write(f'slot({day}).\n')
        
        for team in range(1, total_teams + 1):
            file.write(f'team({team}).\n')
            
        for team_index, slots in enumerate(availabilities, start=1):
            home_slots = [i+1 for i, val in enumerate(slots) if val == 1]
            for slot in home_slots:
                file.write(f'home_availability({team_index}, {slot}).\n')
        
        for team_index, slots in enumerate(availabilities, start=1):
            away_slots = [i+1 for i, val in enumerate(slots) if val == 0]
            for slot in away_slots:
                file.write(f'away_availability({team_index}, {slot}).\n')
        
        for team_index, slots in enumerate(availabilities, start=1):
            forbidden_slots = [i+1 for i, val in enumerate(slots) if val == 2]
            for slot in forbidden_slots:
                file.write(f'forbidden({team_index}, {slot}).\n')

def main():
    input_dir = r'Instances/'
    

    for filename in os.listdir(input_dir):
        if filename.endswith('.txt'):
            input_path = os.path.join(input_dir, filename)

            total_days, total_teams, availabilities = read_input_file(input_path)

            generate_prolog_file(total_days, total_teams, availabilities, filename)




if __name__ == "__main__":
    main()








