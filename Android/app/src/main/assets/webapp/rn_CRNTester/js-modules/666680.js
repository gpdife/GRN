__d(function(g,r,i,a,m,e,d){'use strict';var t=r(d[0]),n=r(d[1]),o=r(d[2]),c=r(d[3]),s=r(d[4]),l=r(d[5]),u=r(d[6]),p=r(d[7]),h=r(d[8]),f=r(d[9]),x=(function(p){function x(){var t,o;n(this,x);for(var l=arguments.length,u=new Array(l),p=0;p<l;p++)u[p]=arguments[p];return(o=c(this,(t=s(x)).call.apply(t,[this].concat(u)))).state={filter:''},o}return l(x,p),o(x,[{key:"render",value:function(){var n=this,o=this.state.filter,c=/.*/;try{c=new RegExp(String(o),'i')}catch(t){}var s=function(t){return n.props.disableSearch||n.props.filter({example:t,filterRegex:c})},l=this.props.sections.map(function(n){return t({},n,{data:n.data.filter(s)})});return u.createElement(f,{style:v.container},this._renderTextInput(),this.props.render({filteredSections:l}))}},{key:"_renderTextInput",value:function(){var t=this;return this.props.disableSearch?null:u.createElement(f,{style:v.searchRow},u.createElement(h,{autoCapitalize:"none",autoCorrect:!1,clearButtonMode:"always",onChangeText:function(n){t.setState(function(){return{filter:n}})},placeholder:"Search...",underlineColorAndroid:"transparent",style:v.searchTextInput,testID:this.props.testID,value:this.state.filter}))}}]),x})(u.Component),v=p.create({searchRow:{backgroundColor:'#eeeeee',padding:10},searchTextInput:{backgroundColor:'white',borderColor:'#cccccc',borderRadius:3,borderWidth:1,paddingLeft:8,paddingVertical:0,height:35},container:{flex:1}});m.exports=x},666680,[51,3,4,5,8,9,11,55,310,80]);