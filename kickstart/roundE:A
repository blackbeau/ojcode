#include <bits/stdc++.h>

using namespace std;
typedef long long LL;
unordered_map<string,int> ms;
//typedef   unordered_map<string,void *> mstop;
  int dp[400][400][400];
int main()
{
    freopen("input", "r", stdin);
    freopen("output", "w", stdout);
    // ios_base::sync_with_stdio(false);
    // cin.tie(NULL);
    int n,ca=1;;
    cin>>n;
    string st;
    while(n--!=0){
      ms.clear();
      cin>>st;
      int sz=st.size();
      for(int i=0;i<=sz;i++)
       for(int j=0;j<=sz;j++)
        for(int k=0;k<=sz;k++)
         dp[i][j][k]=10000;
      dp[0][0][0]=0;

      for(int i=1;i<=sz;i++)
      { int mt = 10000;
        for(int j=0;j<i;j++)
        for(int k=j;k<=i;k++)
      {
        int flag=0,tt=i;
        if(k==j)dp[i][j][k]=dp[i-1][j][k]+1;
        else {
        for(int ii=k-1;ii>=j;ii--)
        if(st[ii]!=st[(tt--)-1])flag=1;
        //cout<<i-(k-j)<<endl;
        if(flag==0)dp[i][j][k]=min(dp[i-1][j][k]+1,dp[i-(k-j)][j][k]+1);
        else dp[i][j][k]=dp[i-1][j][k]+1;
        //cout<< dp[i][j][k]<<endl;
        }
        if( dp[i][j][k]<mt)mt =dp[i][j][k];
      }
      for(int j=0;j<i;j++)
      for(int k=j;k<=i;k++)
      dp[i][j][k]=min(dp[i][j][k],mt+1);
    }
      int ans=10000;
      for(int j=0;j<=sz;j++)
       for(int k=0;k<=sz;k++)
        if(dp[sz][j][k]<ans)ans=dp[sz][j][k];
      printf("Case #%d: %d\n",ca,ans);
      ca++;
      //st[ca]="abc";
      //cout<<st[ca].find("bc",1)<<endl;
      //   cout<<string::npos<<endl;
    }
}
