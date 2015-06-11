export default {
  name: "extend-discourse-classes",
  initialize: function(container, application) {
    var user = Discourse.User.current();
    if (user != null){
      user.set('score', 0);
      MessageBus.subscribe('/qplum_score/' + user.id, function(score) {
          user.set('score', score);
      });
      Discourse.ajax('/qplum_api/score', {
        dataType: 'json',
        type: 'GET'
      }).then(function(json) {
        user.set('score', json['score']);
      });
    }
  }
};
