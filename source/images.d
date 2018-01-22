module images;

import app;

import std.algorithm;
import std.datetime;
import std.random;
import std.string;
import std.uri;

import vibe.stream.operations;
import vibe.data.json;
import vibe.http.client;

struct ImageCache
{
	bool pending;
	Response res;
	SysTime performedAt;
}

__gshared ImageCache[string] imageCache;

struct Response
{
	struct Item
	{
		string htmlTitle;
		string link;
	}

	Item[] items;
}

Response.Item findRandomImage(string query, bool safe)
{
	query = query.strip.toLower;
	string cacheKey = (safe ? "s" : "u") ~ query;
	auto cache = cacheKey in imageCache;
	if (cache && Clock.currTime(UTC()) - cache.performedAt < 16.hours)
		return cache.res.items.length ? cache.res.items[uniform(0, $)] : Response.Item.init;
	imageCache[cacheKey] = ImageCache(true);
	string url = "https://www.googleapis.com/customsearch/v1?cx=" ~ config.search
		.id.encodeComponent ~ "&key=" ~ config.search.key.encodeComponent ~ (safe
				? "&safe=high" : "") ~ "&searchType=image&q=" ~ query.encodeComponent;
	Response.Item ret;
	requestHTTP(url, (scope req) {  }, (scope resh) {
		if (resh.statusCode != HTTPStatus.ok)
			return;
		Response res;
		try
		{
			res = parseJsonString(resh.bodyReader.readAllUTF8).deserializeJson!Response;
		}
		catch (Exception e)
		{
		}
		imageCache[cacheKey] = ImageCache(false, res, Clock.currTime(UTC()));
		ret = res.items.length ? res.items[uniform(0, $)] : Response.Item.init;
	});
	return ret;
}

unittest
{
	import std.stdio;

	writeln(findRandomImage("kebab", true));
}
