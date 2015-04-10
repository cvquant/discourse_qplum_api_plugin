export default {
  name: "extend-discourse-classes",
  initialize: function(container, application) {
    Discourse.User.reopen({
      score: 0, 
      getScore: function() {
        var thisClass = this;
        return Discourse.ajax("/qplum_api/score", {
          dataType: 'json',
          type: 'GET'
        }).then(function(json) {
          thisClass.set('score', json['score']);
        });
      }
    });    
    var user = Discourse.User.current();
    if (user != null){
      Discourse.ajax("/qplum_api/score", {
          dataType: 'json',
          type: 'GET'
        }).then(function(json) {
          user.set('score', json['score']);
        });
    }
  }
};
