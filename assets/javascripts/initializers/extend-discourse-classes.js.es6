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
        });
      }
    });    
    var user = Discourse.User.current();
    if (user != null){
      Discourse.MessageBus.subscribe("/qplum_score/"+user.id, function(score) {
          user.set('score', score);
      });
      Discourse.ajax("/qplum_api/score", {
        dataType: 'json',
        type: 'GET'
      });
    }
  }
};
