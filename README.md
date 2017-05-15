# Alt Text Bot

## Setup

To check out and run the project, do the following:

```bash
$ git clone
$ cd 
$ bundle
$ touch .env # Set up Environment Variables (see below)
$ foreman
```

### Environment Variables

```text
TWITTER_ACCESS_TOKEN=xxx
TWITTER_ACCESS_SECRET=xxx
TWITTER_CONSUMER_KEY=xxx
TWITTER_CONSUMER_SECRET=xxx
CLOUD_SIGHT_KEY=xxx
USERS=xxx,yyy,zzz
HONEYBADGER_API_KEY=xxx
```

## Project Background

[Visit Alt Text Bot on Twitter](https://twitter.com/alt_text_bot)

### Inspiration

Twitter is an important part of public discourse. As it becomes more and more image heavy, people who are blind are left out of the conversation. That's where Alt-Bot comes in. Alt-Bot fills the gaps in image content using an image recognition API to add text descriptions.

The inspiration for the format of the message is a [tweet by @stevefaulkner](https://twitter.com/stevefaulkner/status/589156887628795905), in which he adds alt text to a retweet.

### How it works

Mention @alt_text_bot in a message or retweet that has an image attached, and you'll get a reply with a text description.

Alt-Bot uses APIs from Twitter and [CloudSight](http://cloudsightapi.com/) to retrieve and transcribe images in Tweets.

### Challenges I ran into

Some people asked why anyone cares about meme photos or [what I ate for dinner](https://twitter.com/alt_text_bot/status/589771333015306240). My response was "We don't get to decide who cares". We need to make sure *everyone* is involved in the *entire* conversation, even if it's mostly trivial. We decide for ourselves what's important.

### What I learned

I learned not to expect anyone to work harder for the same content. The people I talked to wanted image descriptions inline instead of posting or retweeting. I've already started work on a Twitter client to make this possible.

### What's next for @alt_text_bot

Alt-Bot needs to be "push" rather than "pull". That means that I'll be creating a Twitter client that adds descriptions inline as part of the feed.
