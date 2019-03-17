import argparse
import datetime
import json
import os
import re

from lxml import html

RE_NONWORD = re.compile(r'\W', re.A)
RE_STOP = re.compile(r'\. |!')


def make_slug(post):
    """Make URL slug for post."""
    date = post['creationTime'].split(' ')[0]
    summary = '-'.join(w.lower() for w in RE_NONWORD.split(summarize(post, 4)) if w)
    postid = post['url'].rsplit('/')[-1]

    return '{}-{}-{}'.format(date, summary, postid)


def summarize(post, max_words=8):
    """Summarize a post, up to `max_words`."""
    content = get_text_content(post)

    words = RE_STOP.split(content, 1)[0].split()
    if len(words) > max_words:
        words = words[:max_words] + ["…"]

    return ' '.join(words)


def get_text_content(post):
    """Get text contents of a post."""
    if 'content' in post:
        return html.fromstring(post['content']).text_content()
    elif 'link' in post:
        return post['link'].get('title', post['link']['url'])
    elif 'resharedPost' in post:
        return get_text_content(post['resharedPost'])
    else:
        return 'Post'


def parse_datetime(s):
    """Parse datetime from Takeout string."""
    return datetime.datetime.strptime(s, '%Y-%m-%d %H:%M:%S%z')


def write_post(f, post):
    """Write post to file."""
    f.write('<article>\n')

    f.write('<header>\n')
    f.write('<img src="{}" style="border-radius: 50%">'.format(
        post['author'].get('avatarImageUrl', '')))
    f.write('<strong><span class="author">{}</span></strong>'.format(
        post['author']['displayName']))
    if 'creationTime' in post:
        creation_time = parse_datetime(post['creationTime'])
        f.write(' <time datetime="{}" title="{}">{:%d %b %Y}</time>'.format(
            creation_time.isoformat('T'),
            creation_time.isoformat(' '),
            creation_time))
    f.write('</header>\n')

    content = post.get('content')
    if content:
        f.write('<div class="content">{}</div>'.format(content))

    media = post.get('media')
    if media:
        write_media(f, media)

    album = post.get('album')
    if album:
        for media in post['album'].get('media', []):
            write_media(f, media)

    location = post.get('location')
    if location:
        f.write('<div class="location" style="text-align: right"><a href="{}">{}</a></div>'.format(
            'https://maps.google.com?ll={lat},{long}&q={lat},{long}'.format(lat=location['latitude'], long=location['longitude']),
            location['displayName'],
        ))

    reshared_post = post.get('resharedPost')
    if reshared_post:
        f.write('<blockquote cite="{}">\n'.format(reshared_post['url']))
        write_post(f, reshared_post)
        f.write('</blockquote>\n')

    link = post.get('link')
    if link:
        url = link['url']
        title = link.get('title', url)
        f.write('<hr>\n')
        f.write('<a href="{}">\n'.format(url))
        f.write('<h2>{}</h2>\n'.format(title))
        if 'imageUrl' in link:
            f.write('<img src="{}" style="max-width: 530px; max-height: 530px">\n'.format(link['imageUrl']))
        f.write('</a>\n')

    f.write('</article>\n')

    f.write('<hr>\n')

    plus_ones = post.get('plusOnes')
    if plus_ones:
        f.write('<div class="plusOnes" style="text-align: right"><strong>(+1\'s)</strong> {}</div>'.format(len(plus_ones)))

    for comment in post.get('comments', []):
        write_post(f, comment)


def write_media(f, media):
    """Write media to file."""
    f.write('<div class="media">')
    if media['contentType'].startswith('image/'):
        f.write('<img src="{}" style="max-width: 530px; max-height: 530px">\n'.format(media['url']))
    else:
        f.write('<object type="{}" data="{}" style="max-width: 530px; max-height: 530px">'.format(
            media['contentType'],
            media['url']))
        f.write('<a href="{}">[Media]</a>'.format(media['url']))
        f.write('</object>\n')
    f.write('</div>')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dir')
    args = parser.parse_args()

    posts = os.path.join(args.dir, 'Google+ Stream', 'Posts')
    for dirpath, dirnames, filenames in os.walk(posts):
        for name in filenames:
            with open(os.path.join(dirpath, name), encoding='utf-8') as f:
                post = json.load(f)

            if not post['postAcl'].get('isPublic'):
                continue

            print(f.name)
            slug = make_slug(post)

            with open(slug + '.html', 'w', encoding='utf-8') as f:
                f.write('---\n')
                f.write('title: {}\n'.format(json.dumps("G+: " + summarize(post))))
                f.write('layout: post\n')
                f.write('---\n\n')

                write_post(f, post)


if __name__ == '__main__':
    main()
