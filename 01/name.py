from faker import Faker
import csv

fake = Faker()

# Generate 100 unique English names
names = set()

while len(names) < 100:
    names.add(fake.name())

# Write the names to a CSV file
with open('names.csv', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['Name'])
    for name in names:
        writer.writerow([name])