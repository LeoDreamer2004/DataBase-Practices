import requests
from bs4 import BeautifulSoup
import csv

url = "https://www.luogu.com.cn/problem/list"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) '
                  'Chrome/58.0.3029.110 Safari/537.3'
}

response = requests.get(url, headers=headers)
soup = BeautifulSoup(response.text, 'html.parser')
problems = soup.find_all('li')
problem = set()
for p in problems:
    problem.add(p.text)
with open('problems.csv', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['Problem'])
    for p in problem:
        writer.writerow([p])