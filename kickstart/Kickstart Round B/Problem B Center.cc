#include <bits/stdc++.h>
using namespace std;
typedef long long LL;
typedef pair<double, double> P;
typedef pair<P, LL> PP;

vector<P> px(110000);
vector<P> py(110000);
int main() {
  // #ifndef ONLINE_JUDGE
  freopen("input", "r", stdin);
  freopen("output", "w", stdout);
  int T, k,N=1;
  cin >> T;
  while (T-- != 0) {
    cin >> k;
    double t = 0;
    double sum=0;;
    for (int i = 0; i < k; i++) {

      cin >> px[i].first >> py[i].first >> t;
      px[i].second = py[i].second = t;
      sum+=t;
      double tt= px[i].first ;
       px[i].first-=py[i].first;
       py[i].first+=tt;
    }
    auto pyy=py,pxx=px;
    sort(px.begin(),px.begin()+k);
    double xx,yy,tsum=0;;
    for (int i = 0; i < k; i++){
      if(tsum+px[i].second>=sum/2){xx=px[i].first;break;}
      else tsum+=px[i].second;
    }
    sort(py.begin(),py.begin()+k);
    tsum=0;
    for (int i = 0; i < k; i++){
      if(tsum+py[i].second>=sum/2){yy=py[i].first;break;}
      else tsum+=py[i].second;
    }
    double ans=0;
    for (int i = 0; i < k; i++)
      ans+=(abs(xx-pxx[i].first)+abs(yy-pyy[i].first))*pyy[i].second;
    printf("Case #%d: %.6lf\n",N++,ans/2);
  }
}
