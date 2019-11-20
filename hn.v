import os
import http
import json
import term
import flag

const (
	api = 'https://hacker-news.firebaseio.com/v0'
)

struct Story {
	by          string
	descendants int
	kids        []int
	id          int
	score       int
	// time        int
	title       string
	typ         string  [json:'type']
	url         string
}

fn fetch_story(id int) Story {
	text := http.get_text('${api}/item/${id}.json')
	story := json.decode(Story, text) or { exit(1) }
	return story
}

fn fetch_top_stories(num int) []Story {
	text := http.get_text('${api}/topstories.json')

	stories_ids := json.decode([]int, text) or { exit(1) }

	stories_top_ids := stories_ids.slice(0, num)

	return stories_top_ids.map(fetch_story(it))
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('hn_top')
	fp.version('v0.1.0')
	fp.description('Show top HN news')
	fp.skip_executable()
	top_num := fp.int('num', 5, 'number of top news to show')
	source_urls := fp.bool('source_urls', false, 'show source urls')

	fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}

	println('Fetching last stories...')
	stories := fetch_top_stories(top_num)
	term.cursor_up(1)
	term.erase_toend()

	// Print stories
	for i, story in stories {
		len := '${i + 1}'.len
		indent := ' '.repeat(2 + len)
		println('${i + 1}. ${term.bold(story.title)}')
		println('${indent}score: ${story.score}    comments: ${story.descendants}    user: ${story.by}')
		url := 'url: https://news.ycombinator.com/item?id=${story.id}'
		println('${indent}${term.dim(url)}')

		if source_urls {
			source_url := 'source: ${story.url}'
			println('${indent}${term.dim(source_url)}')
		}
	}
}
