#include <bits/stdc++.h>

using namespace std;
typedef long long LL;
typedef pair<double, double> P;
typedef pair<P, LL> PP;

vector<string> vs(1000);
int vv[110][110];
int dp[110][110][110];
int T,n,m,k,N=1,mm=0;
int calc(int i){
  return i*(1+1+2*(i-1))/2;
}
// int dfs(int i,int j,int t){
//    //cout<<i<<" "<<j<<endl;
//    if(j==0||i==n+1)return 0;
//    if(dp[i][j]!=-1)return dp[i][j];
//    int max=0;
//    for(int ii=1;ii<=vi[i];ii++){
//      if(max<dfs(i+ii,k-1)+calc(ii)){max=dfs(i+ii,k-1)+calc(ii);}
//
//    }
//    return dp[i][j]=max;
// }

int dfs(int i,int j,int t){
//  cout<<i<<" "<<j<<" "<<t<<endl;
  if(t==0)return 0;
  //cout<<n<<endl;
  if(i==n){return -100000;}
  if(dp[i][j][t]!=-1)return dp[i][j][t];
  int max=-100000;
  if(vv[i][j]==0)return -100000;
  for(int ii=1;ii<=vv[i][j];ii++)
    {
      for(int jj=j-ii+1;jj<=j+ii-1;jj++)
      { auto temp=dfs(i+ii,jj,t-1)+calc(ii);
        //cout<<temp<<endl;
        if(max<temp)max=temp;
      }
    }
  //cout<<max<<endl;
  if(max>mm)mm=max;
  return dp[i][j][t]=max;
}
int check(int i,int j){
  int ans=0;
  while(1){
    for(int ii=j-ans;ii<=j+ans;ii++)
    {
      //cout<<" "<<ii<<"?";
      if(!(ans+i>=0&&ans+i<n&&ii>=0&&ii<m)||vs[ans+i][ii]!= '#'){return ans;}
    }
    ans++;
  }
  //return ans;
}

int main() {
  // #ifndef ONLINE_JUDGE
  freopen("input", "r", stdin);
  freopen("output", "w", stdout);
  cin >> T;
  while (T-- != 0) {
    mm=0;
    cin>>n>>m>>k;
    for(int i=0;i<n;i++)
      cin>>vs[i];
    memset(vv,0,sizeof(vv));
    for(int i=0;i<n;i++)
       for(int j=0;j<m;j++)
         {vv[i][j]=check(i,j);}
      //cout<<ans<<endl;
    memset(dp,-1,sizeof(dp));
    for(int i=0;i<n;i++)
       for(int j=0;j<m;j++)
          if(dp[i][j][k]==-1)dfs(i,j,k);
    // int ans=0;
    // for(int i=0;i<n;i++)
    //   if(dp[i][k]>ans)ans=dp[i][k];
    printf("Case #%d: %d\n",N++,mm);
    //cout<<ans<<endl;

  }
}
