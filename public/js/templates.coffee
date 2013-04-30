window.jenkinsMessageTemplate = () ->
  div class: "jenkins message clearfix", ->
    span class: "column icon", ->
      span class: "icon icon-cogs", ->
    span class: "column author", -> "Jenkins"
    span class: "column job", ->
      a target: "_blank", href: @job.url, -> @job.name
    span class: "column build", ->
      a target: "_blank", href: @build.url, -> @job.number
    span class: "column phase #{ @phase.toLowerCase() }", -> @phase.toCapitalCase()
    span class: "column status #{ @status.toLowerCase() }", -> @status.toCapitalCase()

window.githubCommitTemplate = () ->
  div class: "github message clearfix", ->
    span class: "column icon", ->
      span class: "icon icon-github", ->
    span class: "column author", ->
      a href: "http://github.com/" + @pusher.name, target: "_blank", ->
        @pusher.name
    span class: "column action", -> "pushed to"
    span class: "column branch", -> @ref.replace("refs/heads/", "")
    span class: "column hash before", -> @before.substr(0,5)
    span class: "column", -> "to"
    span class: "column hash after",  -> @after.substr(0,5)
    span class: "column count",  -> @commits.length
    time class: "column time", -> prettyDate(@timestamp)
    # "compare" (compare link)
    # "created":false,
    # "deleted":false,
    # "forced":false,
    # "ref":"refs/heads/master",
    # "repository":
    # "pusher.name"

window.gitCommitTemplate = () ->
  div class: "git message clearfix", ->
    span class: "column icon", ->
      span class: "icon icon-github-sign", ->
    span class: "column author", -> @user
    span class: "column action", -> "pushed to"
    span class: "column branch", -> @ref
    span class: "column hash before", -> @before.substr(0,5)
    span class: "column", -> "to"
    span class: "column hash after",  -> @after.substr(0,5)
    span class: "column count",  -> @commits.length
    time class: "column time", -> prettyDate(@timestamp)

window.gitCommitDetailTemplate = ->
  div ->
    div class: "detail-content git", ->
      div class: "commits" ,->
        div, -> @commits.length + " commits"
        for commit in @commits
          div class: "commit", ->
            div class: "meta clearfix", ->
              span class: "column id", -> commit.id.substr(0,5)
              span class: "column author", -> commit.author.name + " <#{ commit.author.email }> "
            div class: "message", -> commit.message


