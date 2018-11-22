#written by ruth


from os import listdir
from string import punctuation
from nltk.corpus import stopwords
from nltk.stem import PorterStemmer
from nltk import pos_tag
from json import loads,dumps
from random import seed
seed(1000)


class preProcessor(object):
    def __init__(self, inputdir, stops, negtags):
        #data source for unprocessed text
        self.inputdir = inputdir
        #stop words
        self.stops = stops
        #unwanted parts-of-speech tags
        self.negtags = negtags

    def removePuncs(self, text):
        puncs = [i for i in punctuation]
        for i in puncs:
            text = text.replace(i,"")
        return text


    def preProcess(self, text,forumwords):
        #remove punctuations
        text = self.removePuncs(text)

        #split text to words
        words = [word.strip().lower() for word in text.split()]
        #remove stopwords and numbers
        stops = self.stops+forumwords
        words = [word for word in words if word not in stops and word.isalpha()]
        #pos_tag words
        tagged = pos_tag(words)
        #remove unwanted tags
        tagged = [tag for tag in tagged if tag[1] not in self.negtags]
        words = [word[0] for word in tagged]
        #stem words
        words = [PorterStemmer().stem(word) for word in words]
        #join words to form sentence
        sentence = " ".join([word.strip() for word in words])
        return sentence

    def processFile(self, inputfile, outputfile, forumwords):
        with open(inputfile, "r+") as infile:
            inputdata = loads(infile.read())
        infile.close()

        print("Collected Unprocessed data \nProcessing Data .....\n")

        with open(outputfile, "w+") as outfile:
            for data in inputdata:
                text = data.get("text")
                print(text)
                text = self.preProcess(text, forumwords=forumwords)
                print(text)
                if len(text.split()) > 2:
                    outfile.write(text+"\n")
                else:
                    pass
        outfile.close()

    def preProcessTwitter(self):
        twitterDir = self.inputdir+"twitter/"
        files = listdir(twitterDir)
        twitterwords=['post', 'tweet']+[i.replace(".json","").lower() for i in files]

        with open("outputfiles/"+"twitter.txt", "w+") as outfile:
            for i in files:
                try:
                    inputdir = twitterDir+i
                    with open(inputdir, "r+") as infile:
                        inputdata = loads(infile.read())
                        print(inputdata)
                    infile.close()

                    for data in inputdata:
                        text = data.get("text")
                        if text:
                            #remove retweets
                            if "rt" not in text.lower() and len(text.split()) > 2:
                                text = self.preProcess(text,forumwords=twitterwords)
                                outfile.write(text+"\n")
                            else:
                                pass
                        else:
                            pass

                    print("Processed "+i)
                except:
                    pass

        outfile.close()

        return 0

    def prePreocessStackOverflow(self):
        inputfile = "../DataCollection/Krypton/outputfiles/stackoverflow.json"
        outputfile = "outputfiles/stack.txt"
        forumwords = ['post','question','answer','questions','answers', 'votes','vote','upvote', 'downvote','up','down']
        self.processFile(inputfile=inputfile, outputfile=outputfile, forumwords=forumwords)
        return 0

    def preProcessCwn(self):
        inputfile = "../DataCollection/Krypton/outputfiles/cwn.json"
        outputfile = "outputfiles/cwn.txt"
        self.processFile(inputfile=inputfile, outputfile=outputfile, forumwords=[])
        return 0


    def preProcessReddit(self):
        inputfile = self.inputdir+"reddit.json"
        outputfile = "outputfiles/reddit.txt"
        forumwords = ['post', 'votes','vote','upvote', 'downvote','up','down', 'sub', 'reddit','subreddit']
        self.processFile(inputfile=inputfile, outputfile=outputfile, forumwords=forumwords)
        return 0

    def prePreocessHackernews(self):
        inputfile = "../DataCollection/Krypton/outputfiles/hackernews.json"
        outputfile = "outputfiles/hackernews.txt"
        forumwords = ['another','day']
        self.processFile(inputfile=inputfile, outputfile=outputfile, forumwords=forumwords)
        return 0


if __name__ == "__main__":
    inputdir = "../DataCollection/Krypton/outputfiles/"
    negtags = ["NN", "NNP", "NNPS", "POS", "PRP", "PRP$", "WP", "WP$", "IN", "EX", "CC", "DT", "PDT", "WDT","TO", "RP","FW", "MD", "SYM"]
    stops = [stop.lower() for stop in list(set(stopwords.words("english")))]


    pp = preProcessor(inputdir=inputdir, stops=stops,negtags=negtags)
    '''
    pp.preProcessReddit()
    pp.preProcessCwn()
    pp.preProcessTwitter()
    pp.prePreocessStackOverflow()
    '''
    pp.prePreocessHackernews()
