__d(function(g,r,i,a,m,e,d){'use strict';var t=r(d[0]),n=r(d[1]),l=r(d[2]),o=r(d[3]),s=r(d[4]),c=r(d[5]),p=r(d[6]),u=p.Animated,h=p.Image,f=p.ScrollView,x=p.StyleSheet,y=p.Text,E=p.View,b=(function(p){function x(){var n,s;t(this,x);for(var c=arguments.length,p=new Array(c),h=0;h<c;h++)p[h]=arguments[h];return(s=l(this,(n=o(x)).call.apply(n,[this].concat(p)))).state={scrollX:new u.Value(0)},s}return s(x,p),n(x,[{key:"render",value:function(){var t=this.props.panelWidth;return c.createElement(E,{style:v.container},c.createElement(f,{automaticallyAdjustContentInsets:!1,scrollEventThrottle:16,onScroll:u.event([{nativeEvent:{contentOffset:{x:this.state.scrollX}}}]),contentContainerStyle:{flex:1,padding:10},pagingEnabled:!0,horizontal:!0},c.createElement(E,{style:[v.page,{width:t}]},c.createElement(h,{style:{width:180,height:180},source:w}),c.createElement(y,{style:v.text},"I'll find something to put here.")),c.createElement(E,{style:[v.page,{width:t}]},c.createElement(y,{style:v.text},'And here.')),c.createElement(E,{style:[v.page,{width:t}]},c.createElement(y,null,'But not here.'))),c.createElement(u.Image,{pointerEvents:"none",style:[v.bunny,{transform:[{translateX:this.state.scrollX.interpolate({inputRange:[0,t,2*t],outputRange:[0,0,t/3],extrapolate:'clamp'})},{translateY:this.state.scrollX.interpolate({inputRange:[0,t,2*t],outputRange:[0,-200,-260],extrapolate:'clamp'})},{scale:this.state.scrollX.interpolate({inputRange:[0,t,2*t],outputRange:[.5,.5,2],extrapolate:'clamp'})}]}],source:_}))}}]),x})(c.Component),v=x.create({container:{backgroundColor:'transparent',flex:1},text:{padding:4,paddingBottom:10,fontWeight:'bold',fontSize:18,backgroundColor:'transparent'},bunny:{backgroundColor:'transparent',position:'absolute',height:160,width:160},page:{alignItems:'center',justifyContent:'flex-end'}}),w={uri:'https://scontent-sea1-1.xx.fbcdn.net/hphotos-xfa1/t39.1997-6/10734304_1562225620659674_837511701_n.png'},_={uri:'https://scontent-sea1-1.xx.fbcdn.net/hphotos-xaf1/t39.1997-6/851564_531111380292237_1898871086_n.png'};m.exports=b},666760,[3,4,5,8,9,11,15]);