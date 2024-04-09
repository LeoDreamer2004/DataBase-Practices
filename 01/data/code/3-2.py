from collections import Counter


n, c = map(int, input().split())
numberdic = {}
all_dic = dict(Counter(map(int, input().split())))
answer = 0
for i in all_dic.keys():
    try:
        answer += all_dic[i] * all_dic[i + c]
    except KeyError:
        pass
print(answer)
