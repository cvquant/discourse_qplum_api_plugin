export default {
  name: "extend-discourse-classes",

  initialize: function(container, application) {
    Discourse.User.reopen({
      score : 0, 
    
      getScore: function() {
        var thisClass = this;
        return Discourse.ajax("/qplum_api/score", {
          dataType: 'json',
          type: 'GET'
        }).then(function(json) {
          thisClass.score = json['score'];
        });
      }
    });
    if (Discourse.User.current() != null){
      var user = Discourse.User.current();      
    }
  }
};