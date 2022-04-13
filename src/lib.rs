use wasi_interface_gen::wasi_interface;

#[wasi_interface]
mod component {

    struct PolarityScores {
        compound: f64,
        positive: f64,
        negative: f64,
        neutral: f64,
    }

    fn sentimentable(input: String) -> Vec<PolarityScores> {
        lazy_static::lazy_static! {
            static ref ANALYZER: vader_sentiment::SentimentIntensityAnalyzer<'static> =
                vader_sentiment::SentimentIntensityAnalyzer::new();
        }

        let scores = ANALYZER.polarity_scores(input.as_str());
        vec![PolarityScores {
            compound: scores["compound"],
            positive: scores["pos"],
            negative: scores["neg"],
            neutral: scores["neu"],
        }]
    }
}
