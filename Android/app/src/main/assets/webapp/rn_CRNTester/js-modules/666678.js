__d(function(g,r,i,a,m,e,d){'use strict';var t=r(d[0]),n=r(d[1]),l=r(d[2]),s=r(d[3]),o=r(d[4]),p=r(d[5]),u=(r(d[6]).Platform,r(d[7])),c=r(d[8]),f=r(d[9]),h=(function(h){function x(){return t(this,x),l(this,s(x).apply(this,arguments))}return o(x,h),n(x,[{key:"renderExample",value:function(t,n){var l=t.description,s=t.platform,o=t.title;if(s){if("ios"!==s)return null;o+=' ('+s+' only)'}return p.createElement(u,{key:n,title:o,description:l},t.render())}},{key:"render",value:function(){var t=this;if(1===this.props.module.examples.length)return p.createElement(f,{title:this.props.title},this.renderExample(this.props.module.examples[0]));var n=[{data:this.props.module.examples,title:'EXAMPLES',key:'e'}];return p.createElement(f,{title:this.props.title},p.createElement(c,{testID:"example_search",sections:n,filter:function(t){var n=t.example;return t.filterRegex.test(n.title)},render:function(n){return n.filteredSections[0].data.map(t.renderExample)}}))}}]),x})(p.Component);m.exports=h},666678,[3,4,5,8,9,11,15,666679,666680,666681]);