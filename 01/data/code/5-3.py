N = int(input())
if N == 1:
    print(1)
    exit(0)


def f(x):
    """x中除了5的倍数之外所有数之积mod5的余数"""
    j = x // 5
    for i in range(1, x % 5 + 1):
        ans *= i
    return ans % 5


ans = 1
k = 0
while N:
    ans = (ans * f(N)) % 5
    N //= 5
    k += 
# 后面k个0，10的k次方的倍数
if k % 4 == 1:
    ans *= 3
elif k % 4 == 2:
    ans *= 4
elif k % 4 == 3:
    ans *= 2
print([0, 6, 2, 8, 4][ans % 5])
