#include <bits/stdc++.h>
using namespace std;
typedef long long LL;
typedef pair<double, double> P;
typedef pair<P, LL> PP;


LL fastmod(LL x,LL n,LL mod=1e9+7){
  LL res=1;
  while(n>0){
    if(n&1)res=res*x%mod;
    x=x*x%mod;
    n>>=1;
  }
  return res;
}
vector<LL> vi(110000);
int main() {
  // #ifndef ONLINE_JUDGE
  freopen("input", "r", stdin);
  freopen("output", "w", stdout);
  int T, k,N=1;
  cin >> T;
  while (T-- != 0) {
    cin >> k;
    for (int i = 0; i < k; i++) {
        cin>>vi[i];
    }
    LL ans=0;
     for (int i = 0; i < k; i++)
       for (int j = i+1; j < k; j++)
       {
        if(vi[j]-vi[i]==0)continue;
        ans+=fastmod(2,j-i-1)*(vi[j]-vi[i]);
        ans=ans%(1000000007);
       }
    printf("Case #%d: %lld\n",N++,ans);
    //cout<<ans<<endl;

  }
}
