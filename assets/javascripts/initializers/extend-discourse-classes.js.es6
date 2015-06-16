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
    //Overriding show method of user-card controller for getting user score also.
    Discourse.UserCardController.reopen({
      show: function(username, postId, target) {
        // XSS protection (should be encapsulated)
        username = username.toString().replace(/[^A-Za-z0-9_]/g, "");
        // Don't show on mobile
        if (Discourse.Mobile.mobileView) {
          const url = "/users/" + username;
          Discourse.URL.routeTo(url);
          return;
        }
        const currentUsername = this.get('username'),
        wasVisible = this.get('visible'),
        previousTarget = this.get('cardTarget'),
        post = this.get('viewingTopic') && postId ? this.get('postStream').findLoadedPost(postId) : null;
        if (username === currentUsername && this.get('userLoading') === username) {
          // debounce
          return;
        }
        if (wasVisible) {
          this.close();
          if (target === previousTarget) {
            return;  // Same target, close it without loading the new user card
          }
        }

        this.setProperties({ username, userLoading: username, cardTarget: target, post });

        const args = { stats: false };
        args.include_post_count_for = this.get('controllers.topic.model.id');

        return Discourse.User.findByUsername(username, args).then((user) => {
          if (user.topic_post_count) {
            this.set('topicPostCount', user.topic_post_count[args.include_post_count_for]);
          }
          user.score = undefined;
          this.setProperties({ user, avatar: user, visible: true });
          var me = this;
          Discourse.ajax('/qplum_api/score?id=' + user.id, {
            dataType: 'json',
            type: 'GET'
          }).then(function(json) {
            me.get('user').set('score', json.score)
          });
        }).catch((error) => {
          this.close();
          throw error;
        }).finally(() => {
          this.set('userLoading', null);
        });
      }
    });

    //overriding batch model updating batch score in model level

    Discourse.Badge.reopenClass({
      /**
        Create `Discourse.Badge` instances from the server JSON response.
        @method createFromJson
        @param {Object} json The JSON returned by the server
        @returns Array or instance of `Discourse.Badge` depending on the input JSON
        @Overrided: for updating batch score
      **/
      createFromJson: function(json) {
        // Create BadgeType objects.
        var badgeTypes = {};
        if ('badge_types' in json) {
          json.badge_types.forEach(function(badgeTypeJson) {
            badgeTypes[badgeTypeJson.id] = Ember.Object.create(badgeTypeJson);
          });
        }

        var badgeGroupings = {};
        if ('badge_groupings' in json) {
          json.badge_groupings.forEach(function(badgeGroupingJson) {
            badgeGroupings[badgeGroupingJson.id] = Discourse.BadgeGrouping.create(badgeGroupingJson);
          });
        }

        // Create Badge objects.
        var badges = [];
        if ("badge" in json) {
          badges = [json.badge];
        } else {
          badges = json.badges;
        }
        badges = badges.map(function(badgeJson) {
          var badge = Discourse.Badge.create(badgeJson);
          if(badgeTypes[badge.badge_type_id] && badgeTypes[badge.badge_type_id].name.toLowerCase() === 'gold') {
            badge.set('score', 250);
          } else if(badgeTypes[badge.badge_type_id] && badgeTypes[badge.badge_type_id].name.toLowerCase() === 'silver') {
            badge.set('score', 100);
          } else if(badgeTypes[badge.badge_type_id] && badgeTypes[badge.badge_type_id].name.toLowerCase() === 'bronze') {
            badge.set('score', 10);
          }
          badge.set('badge_type', badgeTypes[badge.get('badge_type_id')]);
          badge.set('badge_grouping', badgeGroupings[badge.get('badge_grouping_id')]);
          return badge;
        });

        if ("badge" in json) {
          return badges[0];
        } else {
          return badges;
        }
      }
    });
  }
};
