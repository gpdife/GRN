__d(function(g,r,i,a,m,e,d){'use strict';var t=r(d[0]),n=r(d[1]),l=r(d[2]),o=r(d[3]),u=r(d[4]),c=r(d[5]),s=r(d[6]),p=s.Alert,f=s.Button,h=s.InputAccessoryView,y=s.ScrollView,x=s.StyleSheet,b=s.Text,w=s.TextInput,k=s.View,E=(function(s){function p(){return t(this,p),l(this,o(p).apply(this,arguments))}return u(p,s),n(p,[{key:"render",value:function(){return c.createElement(k,{style:I.textBubbleBackground},c.createElement(b,{style:I.text},"Text Message"))}}]),p})(c.PureComponent),v=(function(s){function h(){var n,u;t(this,h);for(var c=arguments.length,s=new Array(c),p=0;p<c;p++)s[p]=arguments[p];return(u=l(this,(n=o(h)).call.apply(n,[this].concat(s)))).state={text:''},u}return u(h,s),n(h,[{key:"render",value:function(){var t=this;return c.createElement(k,{style:I.textInputContainer},c.createElement(w,{style:I.textInput,onChangeText:function(n){t.setState({text:n})},value:this.state.text,placeholder:'Type a message...'}),c.createElement(f,{onPress:function(){p.alert('You tapped the button!')},title:"Send"}))}}]),h})(c.PureComponent),C=(function(s){function p(){return t(this,p),l(this,o(p).apply(this,arguments))}return u(p,s),n(p,[{key:"render",value:function(){return c.createElement(c.Fragment,null,c.createElement(y,{style:I.fill,keyboardDismissMode:"interactive"},Array(15).fill().map(function(t,n){return c.createElement(E,{key:n})})),c.createElement(h,{backgroundColor:"#fffffff7"},c.createElement(v,null)))}}]),p})(c.Component),I=x.create({fill:{flex:1},textInputContainer:{flexDirection:'row',alignItems:'center',borderTopWidth:1,borderTopColor:'#eee',height:44},textInput:{flex:1,paddingLeft:10},text:{padding:10,color:'white'},textBubbleBackground:{backgroundColor:'#2f7bf6',borderRadius:20,width:110,margin:20}});e.title='<InputAccessoryView>',e.description='Example showing how to use an InputAccessoryView to build an iMessage-like sticky text input',e.examples=[{title:'Simple view with sticky input',render:function(){return c.createElement(C,null)}}]},666711,[3,4,5,8,9,54,15]);