#include<bits/stdc++.h>
using namespace std;
int main(){
	int n;
	cin>>n;
	long long num=1;
	for(int i=1;i<=n;i++){
		num*=i;
		while(1){
			if(num%10==0) num/=10;
			else break;
		}
		num%=100000000;
	}
	cout<<num%10<<endl;
	return 0;
}