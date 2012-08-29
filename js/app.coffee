@App = Ember.Application.create()

App.ApplicationView = Ember.View.extend
  templateName: 'application'

App.ApplicationController = Ember.Controller.extend()

App.AllContributorsController = Ember.ArrayController.extend()
App.AllContributorsView = Ember.View.extend
  templateName: 'contributors'

App.OneContributorController = Ember.ObjectController.extend()
App.OneContributorView = Ember.View.extend
  templateName: 'a-contributor'

App.DetailsView = Ember.View.extend
  templateName: 'details'

App.ReposView = Ember.View.extend
  templateName: 'repos'

App.Contributor = Ember.Object.extend
  loadRepos: ->
    $.ajax
      url: 'https://api.github.com/users/%@/repos'.fmt(@get('login'))
      context: this
      dataType: 'jsonp'
      success: (resp) ->
        this.set 'repos', resp.data

  loadMoreDetails: ->
    $.ajax
      url: 'https://api.github.com/users/%@'.fmt(@get('login'))
      context: this
      dataType: 'jsonp'
      success: (resp) ->
        this.setProperties resp.data



App.Contributor.reopenClass
  allContributors: []
  notContributors: []
  findOne: (username) ->
    contributor = App.Contributor.create
      login: username

    $.ajax
      url: 'https://api.github.com/repos/emberjs/ember.js/contributors'
      dataType: 'jsonp'
      context: contributor
      success: (resp) ->
        this.setProperties(resp.data.filterProperty('login', username))
    contributor
    
  find: ->
    x = this
    $.ajax
      url: 'https://api.github.com/repos/emberjs/ember.js/contributors'
      dataType: 'jsonp'
      context: this
      success: (resp) ->
        os = (App.Contributor.create(c) for c in resp.data)
        @allContributors.addObjects os
        @notContributors.addObjects resp.data

    window.not_contribs = @notContributors
    window.contribs = @allContributors
    return @allContributors


App.Router = Ember.Router.extend
  enableLogging: true
  root: Ember.Route.extend
    contributors: Ember.Route.extend
      route: '/'
      showContributor: Ember.Route.transitionTo('aContributor')
      connectOutlets: (router) ->
        router.get('applicationController')
              .connectOutlet('allContributors', App.Contributor.find())


    aContributor: Ember.Route.extend
      route: '/:githubUserName'

      showAllContributors: Ember.Route.transitionTo('contributors')
      showDetails: Ember.Router.transitionTo('details')
      showRepos: Ember.Router.transitionTo('repos')

      connectOutlets: (router, context) ->
        router.get('applicationController')
              .connectOutlet('oneContributor', context)

      serialize: (router, context) ->
        {githubUserName: context.login}

      deserialize: (router, urlParams) ->
        App.Contributor.findOne(urlParams.githubUserName)

      initialState: 'details'
      details: Ember.Route.extend
        route: '/'
        connectOutlets: (router) ->
          router.get('oneContributorController.content').loadMoreDetails()
          router.get('oneContributorController').connectOutlet('details')

      repos: Ember.Route.extend
        route: '/repos'
        connectOutlets: (router) ->
          router.get('oneContributorController.content').loadRepos()
          router.get('oneContributorController').connectOutlet('repos')

App.initialize()
