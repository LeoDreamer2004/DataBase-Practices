#include <bits/stdc++.h>
using namespace std;

int main()
{
    int k = 0;
    cin >> k;
    int i = 0;
    while (sum <= k)
    {
        i += 1;
        sum += double(1) / double(i);
    }
    cout << i << endl;
    return 0;
}