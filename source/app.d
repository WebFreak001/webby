module app;

import std.stdio, std.algorithm, std.string, std.format, std.conv, std.array,
	std.json, std.traits, std.process, core.time, std.regex, std.random;

import vibe.core.core;
import vibe.core.file;
import vibe.data.json;
import vibe.http.client;

import dscord.core, dscord.util.process, dscord.util.emitter,
	dscord.voice.youtubedl;

import core.sys.posix.signal;
import etc.linux.memoryerror;

import images;

static immutable makeMe = ctRegex!(`^(sudo\s+)?(make|bake|create|order|give)\s+(me|<@!?\d+>)\s+(?:(an?|another|more|many|the|some|such|those|them|these)\s+)?(lewd\s+)?(.*)`,
		"i");

string convertBold(string s)
{
	import std.xml : decode; // it comes from google, so I assume it's proper HTML
	return s.replace("<b>", "**").replace("</b>", "**").decode;
}

class BasicPlugin : Plugin
{
	this()
	{
		super();
	}

	@Listener!(MessageCreate, EmitterOrder.AFTER) void onMessageCreate(MessageCreate event)
	{
		this.log.infof("MessageCreate: %s", event.message.content);
		{
			if (event.message.content.toLower.startsWith("send nudes"))
			{
				auto ret = findRandomImage("dunes", true);
				if (ret != Response.Item.init)
					event.message.reply(
							"<@!" ~ event.message.author.id.to!string
							~ "> but don't share them with anyone! " ~ ret.link);
				return;
			}
		}
		{
			auto match = event.message.content.matchFirst(makeMe);
			if (match)
			{
				string to = "<@!" ~ event.message.author.id.to!string ~ ">";
				if (match[3].length && match[3] != "me")
					to = match[3];
				if (match[1].length)
				{
					auto ret = findRandomImage(match[6], match[5].length ? false : true);
					if (ret == Response.Item.init)
						event.message.reply(to ~ " sorry to disappoint you, but I can't do that right now");
					else
						event.message.reply(to ~ " here you go: " ~ ret.link ~ " (" ~ ret.htmlTitle.convertBold ~ ")");
				}
				else
					event.message.reply("<@!" ~ event.message.author.id.to!string ~ "> permission denied");
				return;
			}
		}
	}

	@Command("kms")
	void onKMS(CommandEvent event)
	{
		event.msg.reply("<:kms:403304933195120640>");
	}
}

struct Config
{
	struct Search
	{
		string key, id;
	}

	Search search;
}

Config config;

void main(string[] args)
{
	static if (is(typeof(registerMemoryErrorHandler)))
		registerMemoryErrorHandler();

	if (args.length <= 1)
	{
		writefln("Usage: %s <token>", args[0]);
		return;
	}

	if (existsFile("config.json"))
	{
		config = readFileUTF8("config.json").deserializeJson!Config;
	}

	BotConfig config;
	config.token = args[1];
	config.cmdPrefix = "!";
	config.cmdRequireMention = false;
	Bot bot = new Bot(config, LogLevel.trace);
	bot.loadPlugin(new BasicPlugin);
	bot.run();
	runEventLoop();
	return;
}
