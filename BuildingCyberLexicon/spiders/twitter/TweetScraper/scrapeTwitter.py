import os
from time import sleep
import json


#use hastags and mentions from cyber war news articles as filters on twitter
def getMentionsAndHashtags():
    with open("../../../outputfiles/cwn.json", "r+") as ff:
        data = ff.read()
        hashtagsMentions, data =[], json.loads(data)
        for dd in data:
            text = dd.get('text')
            for i in text.split():
                if (i.startswith('#') or i.startswith('@')) and (len(i)>3 and len(i)<15):
                    hashtagsMentions.append(i)
        return hashtagsMentions


if __name__ == "__main__":
    hashtags = getMentionsAndHashtags()
    for hashtag in hashtags:
        outfile = "../../../outputfiles/twitter/"+str(hashtag).replace("#","").replace("@","")+".json"
        os.system("scrapy crawl TweetScraper -a query="+hashtag + " -a top_tweet=True" + " -a crawl_user=True"+ " -o "+outfile)
        print(" Scraped tweets from "+hashtag)
        sleep(30)
