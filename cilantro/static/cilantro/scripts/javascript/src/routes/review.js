// Generated by CoffeeScript 1.3.3
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(['environ', 'jquery', 'underscore', 'backbone'], function(environ, $, _, Backbone) {
  var ReviewArea;
  ReviewArea = (function(_super) {

    __extends(ReviewArea, _super);

    function ReviewArea() {
      return ReviewArea.__super__.constructor.apply(this, arguments);
    }

    ReviewArea.prototype.id = '#review-area';

    ReviewArea.prototype.initialize = function() {
      return this.$el.hide().appendTo('#main-area .inner');
    };

    ReviewArea.prototype.load = function() {
      return this.$el.fadeIn();
    };

    ReviewArea.prototype.unload = function() {
      return this.$el.hide();
    };

    ReviewArea.prototype.destroy = function() {};

    return ReviewArea;

  })(Backbone.View);
  return App.register('review/', 'review', new ReviewArea);
});