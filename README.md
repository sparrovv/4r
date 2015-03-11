# pr-analyzer

Explore closed pull requests data from GitHub repository and try to get some insights from them using R.

Some of the questions I was pondering about:

- What's my cycle time? - How long it takes from the first commit to the merging pull request into master.
- Number of pull request per contributor
- Mean/Median number of commits per PR
- Mean/Median number of commits per contributor
- Mean/Median number of comments per PR
- Mean/Median number of comments per contributor
- Number of changed files per PR
- Number of changed files per contributor
- Pull requests trend over a period of time

But that's just a scratch of the surface.

## How to use it

You need to set up .netrc file in your home directory:

```
machine api.github.com
  login ....
  password ....
```

and then:

```ruby
  bundle install
  bundle exec import.rb "user/repo_name"
```

Depending on the amount of pull requests in the repository, it might take some time.

It might happen that your rate limit will exceed, in that case script will wait 1 hour, and resume the import.

### Caching

All requests are cached, so even if we the script is started again it won't re-use the rate limit for already cached PRs.

(If you willing to add a new field to CSV, you just need to modify `PullRequestRecord::ATTRIBUTES`)

## R - Analysis

To install `rstudio` and `r` on Mac:

```sh
  brew tap homebrew/science
  brew install r
  # install brew cask
  brew cask install rstudio
```

### R scripts

