var __hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key]);return ctor.prototype=parent.prototype,child.prototype=new ctor,child.__super__=parent.prototype,child};define(["backbone"],function(Backbone){var DataView,DataViews;return DataView=function(_super){function DataView(){return DataView.__super__.constructor.apply(this,arguments)}return __extends(DataView,_super),DataView.prototype.url=function(){return this.isNew()?DataView.__super__.url.apply(this,arguments):this.get("url")},DataView}(Backbone.Model),DataViews=function(_super){function DataViews(){return DataViews.__super__.constructor.apply(this,arguments)}return __extends(DataViews,_super),DataViews.prototype.model=DataView,DataViews.prototype.getSession=function(){return this.filter(function(model){return model.get("session")})[0]},DataViews}(Backbone.Collection),{DataView:DataView,DataViews:DataViews}})