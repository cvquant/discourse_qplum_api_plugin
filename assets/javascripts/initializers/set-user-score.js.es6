export default {
  name: "set-user-score",
  after: "extend-discourse-classes",

  initialize: function(container, application) {
    var user = Discourse.User.current();
    if (user != null){
      //user.getScore();
    }
  }
};
