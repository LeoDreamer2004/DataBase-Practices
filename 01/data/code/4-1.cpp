#include <bits/stdc++.h>
using namespace std;

int main()
{
    int n, t, ans1 = 0, ans2 = 0;
    scanf("%d", &n);
    int a[n] = {}, dp[n] = {}, met[n] = {}; // 取i号为末尾时最多有多少数？有多少方法？
    for (int i = 0; i < n; i++)
    {
        scanf("%d", &t);
        a[i] = t, dp[i] = 1;
        for (int j = 0; j < i; j++)
            if (a[j] > t)
                dp[i] = max(dp[i], dp[j] + 1);
        ans1 = max(ans1, dp[i]);
    }
    for (int i = 0; i < n; i++)
    {
        if (dp[i] == 1)
            met[i] = 1;
        for (int j = 0; j < i; j++)
        {
            if (a[i] < a[j] && dp[i] == dp[j] + 1)
                met[i] += met[j];
            else if (a[i] == a[j] && dp[i] == dp[j])
                met[i] = 0;
        }
        if (dp[i] == ans1)
            ans2 += met[i];
    }
    printf("%d %d", ans1, ans2);
    return 0;
}