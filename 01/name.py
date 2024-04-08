from faker import Faker
import csv
import random
import string

fake = Faker()

# Generate 100 unique English names, passwords and grades
persons = set()
grades = ['beginner', 'intermediate', 'advanced', 'expert']

def generate_random_string():
    length = random.randint(8, 12)
    possible_characters = string.ascii_letters + string.digits
    random_string = ''.join(random.choice(possible_characters) for _ in range(length))
    return random_string

while len(persons) < 100:
    name = fake.name()
    password = generate_random_string()
    grade = random.choice(grades)
    persons.add((name, password, grade))

# Write the names, passwords and grades to a CSV file
with open('person.csv', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['Name', 'Password', 'Grade'])
    for name, password, grade in persons:
        writer.writerow([name, password, grade])