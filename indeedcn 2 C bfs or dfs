#include <bits/stdc++.h>
using namespace std;
typedef long long LL;
typedef pair<int, int> P;
typedef pair<P,P> PP;
int h,w,d,r;
vector<string> vs(150);
int ans=INT_MAX;
int st[150][150][2];
//int st[150][150];
// bool isok(int i,int j){
//   if(i>=0&&i<h&&j>=0&&j<w&&vs[i][j]=='.'&&st[i][j]==0)return 1;
//   else return 0;
// }


bool isok(int i,int j,int k){
  if(i>=0&&i<h&&j>=0&&j<w&&vs[i][j]=='.'&&st[i][j][k]==0)return 1;
  else return 0;
}
int x[]={-1,1,0,0};
int y[]={0,0,1,-1};
void bfs(){
  queue<PP> qp;
  qp.push({{0,0},{0,0}});
  while(!qp.empty()){
    auto t=qp.front();
    st[t.first.first][t.first.second][t.second.second]=1;
    //cout<<t.first.first<<" "<<t.first.second<<" "<<t.second.second<<endl;
    if(t.first.first==h-1&&t.first.second==w-1){ans=t.second.first;return ;}
    qp.pop();
    for(int i=0;i<4;i++){
      if(isok(t.first.first+x[i],t.first.second+y[i],t.second.second))
        {qp.push({{t.first.first+x[i],t.first.second+y[i]},{t.second.first+1,t.second.second}});}
      if(isok(t.first.first+d,t.first.second+r,t.second.second)&&t.second.second==0)
        {qp.push({{t.first.first+d,t.first.second+r},{t.second.first+1,t.second.second+1}});}
    }
  }
}
//
// void dfs(int i,int j,int k,int sum){
//
//   if(sum==ans)return;
//   if(i==h-1&&j==w-1){if(sum<ans)ans=sum;return ;}
//
//   //cout<<i<<j<<k<<" "<<ans<<endl;
//
//   if(isok(i+1,j)&&vs[i+1][j]=='.'){st[i+1][j]=1;dfs(i+1,j,k,sum+1);st[i+1][j]=0;}
//   if(isok(i-1,j)&&vs[i-1][j]=='.'){st[i-1][j]=1;dfs(i-1,j,k,sum+1);st[i-1][j]=0;}
//   if(isok(i,j+1)&&vs[i][j+1]=='.'){st[i][j+1]=1;dfs(i,j+1,k,sum+1);st[i][j+1]=0;}
//   if(isok(i,j-1)&&vs[i][j-1]=='.'){st[i][j-1]=1;dfs(i,j-1,k,sum+1);st[i][j-1]=0;}
//   if(isok(i+d,j+r)&&vs[i+d][j+r]=='.'&&k==0){st[i+d][j+r]=1;dfs(i+d,j+r,k+1,sum+1);st[i+d][j+r]=0;}
//   return ;
// }
int main() {
  // #ifndef ONLINE_JUDGE
   freopen("input", "r", stdin);
   cin>>h>>w>>d>>r;
   for(int i=0;i<h;i++)
      cin>>vs[i];

   memset(st,0,sizeof(st));
  // dfs(0,0,0,0);
  bfs();
  cout<<ans<<endl;

}
