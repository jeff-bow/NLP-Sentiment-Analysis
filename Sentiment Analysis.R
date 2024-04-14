# Loading the necessary libraries
library(tidyverse)
library(tidytext)
library(tm)
library(dplyr)
library(ggplot2)
library(gridExtra)

# Reading the dataset
reviews <- read.csv("/Users/jeffbowers/Library/Mobile Documents/com~apple~CloudDocs/DCU Final Year/Analytics Portfolio/Portfolio/Sentiment Analysis R/amazon_reviews.csv", stringsAsFactors = FALSE)

# Creating a unique identifier 'reviewID' column
reviews <- reviews %>%
  mutate(reviewID = row_number())

# Preview the dataset
head(reviews)

# Using 'reviewText' as the column with review texts for analysis
# Simplifying the name from reviewText to reviews for user ease and using rename to keep all other columns
reviews <- reviews %>%
  rename(reviews = reviewText) %>%
  # Removing rows with blank data in the reviewText (now reviews) columns as these are useless
  filter(!is.na(reviews))

# Converting the reviews column into a corpus
reviews_corpus <- VCorpus(VectorSource(reviews$reviews))

# Applying text transformations: convert to lowercase, remove punctuation, remove numbers, stem
reviews_corpus <- tm_map(reviews_corpus, content_transformer(tolower))
reviews_corpus <- tm_map(reviews_corpus, removePunctuation)
reviews_corpus <- tm_map(reviews_corpus, removeNumbers)
reviews_corpus <- tm_map(reviews_corpus, stemDocument)

# Converting the corpus back to a plain text vector
stemmed_texts <- sapply(reviews_corpus, as.character)

# Updating the reviews dataframe by replacing the 'reviews' column with stemmed text
reviews$reviews <- stemmed_texts

# Checking to see new processed dataframe
head(reviews)

# Unnesting tokens (words), this takes the words out of sentences and isolates them
reviews_words <- reviews %>%
  unnest_tokens(word, reviews)

# Recommended to use the 'bing' lexicon for sentiment analysis
# Getting sentiments from 'bing' lexicon
sentiments <- get_sentiments("bing")

# Joining the review sentiments with the sentiment lexicon
review_sentiments <- reviews_words %>%
  inner_join(sentiments, by = "word")

# Aggregating sentiment at the document level. (Here we assume each row is a unique review)
review_sentiment_score <- review_sentiments %>%
  count(index = row_number(), sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment_score = positive - negative)

# Summary of sentiment scores
summary(review_sentiment_score$sentiment_score)

# Visualising the distribution of sentiment scores with ggplot library
ggplot(review_sentiment_score, aes(x = sentiment_score)) +
  geom_histogram(bins = 50, fill = "blue", color = "black") +
  theme_minimal() +
  ggtitle("Distribution of Sentiment Scores")


# Tokenizing the words and creating an inner join with the 'bing' lexicon
reviews_sentiment <- reviews %>%
  unnest_tokens(word, reviews) %>%
  inner_join(get_sentiments("bing"), by = "word")


# Calculating sentiment score for each review using 'id' column as unique identifier
review_scores <- reviews_sentiment %>%
  group_by(reviewID) %>%
  summarize(sentiment_score = sum(case_when(sentiment == "positive" ~ 1,
                                            sentiment == "negative" ~ -1,
                                            TRUE ~ 0)))


# Top 10 Positive Sentiments
top_positive <- review_scores %>%
  arrange(desc(sentiment_score)) %>%
  head(10)

# Top 10 Negative Sentiments
top_negative <- review_scores %>%
  arrange(sentiment_score) %>%
  head(10)

# Joining with original reviews to get the text
top_positive_reviews <- top_positive %>%
  inner_join(reviews, by = "reviewID")

top_negative_reviews <- top_negative %>%
  inner_join(reviews, by = "reviewID")

# Printing top positive reviews
print("Top Positive Reviews:")
print(top_positive_reviews)

# Printing top negative reviews
print("Top Negative Reviews:")
print(top_negative_reviews)

# `reviews_sentiment` contains the sentiment analysis results
positive_words <- reviews_sentiment %>%
  filter(sentiment == "positive") %>%
  count(word, sort = TRUE) %>%
  top_n(10, wt = n)

negative_words <- reviews_sentiment %>%
  filter(sentiment == "negative") %>%
  count(word, sort = TRUE) %>%
  top_n(10, wt = n)

# Printing top 10 positive and negative words
print(positive_words)
print(negative_words)

# Bar chart of the top 10 positive words
ggplot(positive_words, aes(x = reorder(word, n), y = n)) +
  geom_col(fill = "green") +  # Draw bars, colored in green
  coord_flip() +  # Flip coordinates to make the chart horizontal
  labs(title = "Top 10 Positive Words by Frequency", 
       x = "Words", 
       y = "Frequency") +  # Labeling the plot
  theme_minimal()  # Used the minimal theme for a cleaner look

# Bar chart of the top 10 negative words
ggplot(negative_words, aes(x = reorder(word, n), y = n)) +
  geom_col(fill = "red") +  # Draw bars, colored in red
  coord_flip() +  # Flip coordinates to make the chart horizontal
  labs(title = "Top 10 Negative Words by Frequency", 
       x = "Words", 
       y = "Frequency") +  # Labeling the plot
  theme_minimal()  # Used the minimal theme for a cleaner look

# Recreating the graphs to display side by side (green positive, red negative)
positive_plot <- ggplot(positive_words, aes(x = reorder(word, n), y = n)) +
  geom_col(fill = "green") +
  coord_flip() +
  labs(title = "Top 10 Positive Words", x = "Words", y = "Frequency") +
  theme_minimal()

negative_plot <- ggplot(negative_words, aes(x = reorder(word, n), y = n)) +
  geom_col(fill = "red") +
  coord_flip() +
  labs(title = "Top 10 Negative Words", x = "Words", y = "Frequency") +
  theme_minimal()

# Displaying plots side by side
grid.arrange(positive_plot, negative_plot, ncol = 2)




