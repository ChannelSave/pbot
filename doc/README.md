# PBot Documentation

## Table of Contents

<!-- md-toc-begin -->
* [QuickStart](QuickStart.md#quickstart)
  * [Installation](QuickStart.md#installation)
    * [Installing Perl](QuickStart.md#installing-perl)
    * [Installing CPAN modules](QuickStart.md#installing-cpan-modules)
    * [Installing PBot](QuickStart.md#installing-pbot)
      * [git (recommended)](QuickStart.md#git-recommended)
      * [Download zip archive](QuickStart.md#download-zip-archive)
  * [First-time Configuration](QuickStart.md#first-time-configuration)
    * [Clone data-directory](QuickStart.md#clone-data-directory)
    * [Quick-start command](QuickStart.md#quick-start-command)
    * [Edit Registry](QuickStart.md#edit-registry)
      * [Recommended settings for IRC Networks](QuickStart.md#recommended-settings-for-irc-networks)
        * [Freenode](QuickStart.md#freenode)
        * [IRCnet](QuickStart.md#ircnet)
        * [Other networks](QuickStart.md#other-networks)
  * [Starting PBot](QuickStart.md#starting-pbot)
    * [Usage](QuickStart.md#usage)
      * [Overriding directories](QuickStart.md#overriding-directories)
      * [Overriding registry](QuickStart.md#overriding-registry)
  * [Additional Configuration](QuickStart.md#additional-configuration)
    * [Adding Channels](QuickStart.md#adding-channels)
    * [Adding Admins](QuickStart.md#adding-admins)
    * [Loading Plugins](QuickStart.md#loading-plugins)
  * [Further Reading](QuickStart.md#further-reading)
    * [Commands](QuickStart.md#commands)
    * [Factoids](QuickStart.md#factoids)
    * [Modules](QuickStart.md#modules)
<!-- md-toc-end -->
<!-- md-toc-begin -->
* [Commands](Commands.md#commands)
  * [Command interpreter](Commands.md#command-interpreter)
    * [Piping](Commands.md#piping)
    * [Substitution](Commands.md#substitution)
    * [Chaining](Commands.md#chaining)
    * [Variables](Commands.md#variables)
    * [Inline invocation](Commands.md#inline-invocation)
  * [Types of commands](Commands.md#types-of-commands)
    * [Built-in commands](Commands.md#built-in-commands)
      * [Creating new built-in commands](Commands.md#creating-new-built-in-commands)
      * [Plugins](Commands.md#plugins)
    * [Factoids](Commands.md#factoids)
      * [Code Factoids](Commands.md#code-factoids)
      * [Modules](Commands.md#modules)
  * [Commands documented here](Commands.md#commands-documented-here)
    * [version](Commands.md#version)
    * [help](Commands.md#help)
    * [uptime](Commands.md#uptime)
  * [Commands documented elsewhere](Commands.md#commands-documented-elsewhere)
<!-- md-toc-end -->
<!-- md-toc-begin -->
* [Administrative](Admin.md#administrative)
  * [Logging in and out](Admin.md#logging-in-and-out)
    * [login](Admin.md#login)
    * [logout](Admin.md#logout)
  * [Admin management commands](Admin.md#admin-management-commands)
    * [adminadd](Admin.md#adminadd)
    * [adminrem](Admin.md#adminrem)
      * [Admin levels](Admin.md#admin-levels)
    * [adminset](Admin.md#adminset)
    * [adminunset](Admin.md#adminunset)
      * [Admin metadata list](Admin.md#admin-metadata-list)
    * [Listing admins](Admin.md#listing-admins)
  * [Channel management commands](Admin.md#channel-management-commands)
    * [join](Admin.md#join)
    * [part](Admin.md#part)
    * [chanadd](Admin.md#chanadd)
    * [chanrem](Admin.md#chanrem)
    * [chanset](Admin.md#chanset)
    * [chanunset](Admin.md#chanunset)
    * [chanlist](Admin.md#chanlist)
      * [Channel metadata list](Admin.md#channel-metadata-list)
    * [ignore](Admin.md#ignore)
    * [unignore](Admin.md#unignore)
    * [whitelist](Admin.md#whitelist)
    * [blacklist](Admin.md#blacklist)
    * [op](Admin.md#op)
    * [deop](Admin.md#deop)
    * [voice](Admin.md#voice)
    * [devoice](Admin.md#devoice)
    * [mode](Admin.md#mode)
    * [ban/mute](Admin.md#banmute)
    * [unban/unmute](Admin.md#unbanunmute)
    * [invite](Admin.md#invite)
    * [kick](Admin.md#kick)
  * [Module management commands](Admin.md#module-management-commands)
    * [load](Admin.md#load)
    * [unload](Admin.md#unload)
    * [Listing modules](Admin.md#listing-modules)
  * [Plugin management commands](Admin.md#plugin-management-commands)
    * [plug](Admin.md#plug)
    * [unplug](Admin.md#unplug)
    * [replug](Admin.md#replug)
    * [pluglist](Admin.md#pluglist)
  * [Command metadata commands](Admin.md#command-metadata-commands)
    * [cmdset](Admin.md#cmdset)
    * [cmdunset](Admin.md#cmdunset)
    * [Command metadata list](Admin.md#command-metadata-list)
  * [Miscellaneous commands](Admin.md#miscellaneous-commands)
    * [export](Admin.md#export)
    * [refresh](Admin.md#refresh)
    * [reload](Admin.md#reload)
    * [sl](Admin.md#sl)
    * [die](Admin.md#die)
<!-- md-toc-end -->
<!-- md-toc-begin -->
* [Factoids](Factoids.md#factoids)
  * [About](Factoids.md#about)
  * [Special commands](Factoids.md#special-commands)
    * [/say](Factoids.md#say)
    * [/me](Factoids.md#me)
    * [/call](Factoids.md#call)
    * [/msg](Factoids.md#msg)
    * [/code](Factoids.md#code)
      * [Supported languages](Factoids.md#supported-languages)
      * [Special variables](Factoids.md#special-variables)
      * [testargs example](Factoids.md#testargs-example)
      * [Setting a usage message](Factoids.md#setting-a-usage-message)
      * [poll/vote example](Factoids.md#pollvote-example)
      * [SpongeBob Mock meme example](Factoids.md#spongebob-mock-meme-example)
      * [Using command-piping](Factoids.md#using-command-piping)
      * [Improving SpongeBob Mock meme](Factoids.md#improving-spongebob-mock-meme)
      * [Formatting and editing lengthy Code Factoids](Factoids.md#formatting-and-editing-lengthy-code-factoids)
  * [Special variables](Factoids.md#special-variables-1)
    * [$args](Factoids.md#args)
    * [$arg[n]](Factoids.md#argn)
    * [$arg[n:m]](Factoids.md#argnm)
    * [$arglen](Factoids.md#arglen)
    * [$channel](Factoids.md#channel)
    * [$nick](Factoids.md#nick)
    * [$randomnick](Factoids.md#randomnick)
    * [$0](Factoids.md#0)
  * [List variables](Factoids.md#list-variables)
    * [Expansion modifiers](Factoids.md#expansion-modifiers)
  * [action_with_args](Factoids.md#action_with_args)
  * [add_nick](Factoids.md#add_nick)
  * [Channel namespaces](Factoids.md#channel-namespaces)
  * [Adding/removing factoids](Factoids.md#addingremoving-factoids)
    * [factadd](Factoids.md#factadd)
    * [factrem](Factoids.md#factrem)
    * [forget](Factoids.md#forget)
    * [factalias](Factoids.md#factalias)
  * [Displaying factoids](Factoids.md#displaying-factoids)
    * [fact](Factoids.md#fact)
    * [factshow](Factoids.md#factshow)
  * [Editing factoids](Factoids.md#editing-factoids)
    * [factchange](Factoids.md#factchange)
    * [factmove](Factoids.md#factmove)
    * [factundo](Factoids.md#factundo)
    * [factredo](Factoids.md#factredo)
  * [Factoid Metadata](Factoids.md#factoid-metadata)
    * [factset](Factoids.md#factset)
    * [factunset](Factoids.md#factunset)
    * [Factoid Metadata List](Factoids.md#factoid-metadata-list)
  * [Information about factoids](Factoids.md#information-about-factoids)
    * [factfind](Factoids.md#factfind)
    * [factinfo](Factoids.md#factinfo)
    * [factlog](Factoids.md#factlog)
    * [factset](Factoids.md#factset-1)
    * [count](Factoids.md#count)
    * [histogram](Factoids.md#histogram)
    * [top20](Factoids.md#top20)
<!-- md-toc-end -->
<!-- md-toc-begin -->
* [Registry](Registry.md#registry)
  * [About](Registry.md#about)
    * [Types of values](Registry.md#types-of-values)
    * [Creating array values](Registry.md#creating-array-values)
    * [Overriding Registry values per-channel](Registry.md#overriding-registry-values-per-channel)
  * [Overriding Registry values via command-line](Registry.md#overriding-registry-values-via-command-line)
  * [Registry commands](Registry.md#registry-commands)
    * [regset](Registry.md#regset)
    * [regunset](Registry.md#regunset)
    * [regchange](Registry.md#regchange)
    * [regshow](Registry.md#regshow)
    * [regfind](Registry.md#regfind)
    * [regsetmeta](Registry.md#regsetmeta)
    * [regunsetmeta](Registry.md#regunsetmeta)
  * [Editing Registry file](Registry.md#editing-registry-file)
  * [Metadata list](Registry.md#metadata-list)
  * [List of known Registry items](Registry.md#list-of-known-registry-items)
    * [Channel-specific Registry items](Registry.md#channel-specific-registry-items)
<!-- md-toc-end -->
<!-- md-toc-begin -->
* [Modules](Modules.md#modules)
  * [About](Modules.md#about)
  * [Creating modules](Modules.md#creating-modules)
  * [Documentation for built-in modules](Modules.md#documentation-for-built-in-modules)
    * [cc](Modules.md#cc)
      * [Usage](Modules.md#usage)
      * [Supported Languages](Modules.md#supported-languages)
      * [Default Language](Modules.md#default-language)
      * [Disallowed system calls](Modules.md#disallowed-system-calls)
      * [Program termination with no output](Modules.md#program-termination-with-no-output)
      * [Abnormal program termination](Modules.md#abnormal-program-termination)
      * [C and C++ Functionality](Modules.md#c-and-c-functionality)
      * [Using the preprocessor](Modules.md#using-the-preprocessor)
        * [Default #includes](Modules.md#default-includes)
        * [Using #include](Modules.md#using-include)
        * [Using #define](Modules.md#using-define)
      * [main() Function Unnecessary](Modules.md#main-function-unnecessary)
      * [Embedding Newlines](Modules.md#embedding-newlines)
      * [Printing in binary/base2](Modules.md#printing-in-binarybase2)
      * [Using the GDB debugger](Modules.md#using-the-gdb-debugger)
        * [print](Modules.md#print)
        * [ptype](Modules.md#ptype)
        * [watch](Modules.md#watch)
        * [trace](Modules.md#trace)
        * [gdb](Modules.md#gdb)
      * [Interactive Editing](Modules.md#interactive-editing)
        * [copy](Modules.md#copy)
        * [show](Modules.md#show)
        * [diff](Modules.md#diff)
        * [paste](Modules.md#paste)
        * [run](Modules.md#run)
        * [undo](Modules.md#undo)
        * [s//](Modules.md#s)
        * [replace](Modules.md#replace)
        * [prepend](Modules.md#prepend)
        * [append](Modules.md#append)
        * [remove](Modules.md#remove)
      * [Some Examples](Modules.md#some-examples)
    * [english](Modules.md#english)
    * [expand](Modules.md#expand)
    * [prec](Modules.md#prec)
    * [paren](Modules.md#paren)
    * [faq](Modules.md#faq)
    * [cfact](Modules.md#cfact)
    * [cjeopardy](Modules.md#cjeopardy)
      * [hint](Modules.md#hint)
      * [what](Modules.md#what)
      * [w](Modules.md#w)
      * [filter](Modules.md#filter)
      * [score](Modules.md#score)
      * [rank](Modules.md#rank)
      * [reset](Modules.md#reset)
      * [qstats](Modules.md#qstats)
      * [qshow](Modules.md#qshow)
    * [c99std](Modules.md#c99std)
    * [c11std](Modules.md#c11std)
    * [man](Modules.md#man)
    * [google](Modules.md#google)
    * [define](Modules.md#define)
    * [dict](Modules.md#dict)
    * [foldoc](Modules.md#foldoc)
    * [vera](Modules.md#vera)
    * [udict](Modules.md#udict)
    * [wdict](Modules.md#wdict)
    * [acronym](Modules.md#acronym)
    * [math](Modules.md#math)
    * [calc](Modules.md#calc)
    * [qalc](Modules.md#qalc)
    * [compliment](Modules.md#compliment)
    * [insult](Modules.md#insult)
    * [excuse](Modules.md#excuse)
    * [horoscope](Modules.md#horoscope)
    * [quote](Modules.md#quote)
<!-- md-toc-end -->
<!-- md-toc-begin -->
* [Quotegrabs](Quotegrabs.md#quotegrabs)
  * [About](Quotegrabs.md#about)
  * [Commands](Quotegrabs.md#commands)
    * [grab](Quotegrabs.md#grab)
    * [getq](Quotegrabs.md#getq)
    * [rq](Quotegrabs.md#rq)
    * [delq](Quotegrabs.md#delq)
<!-- md-toc-end -->
<!-- md-toc-begin -->
* [Anti-Abuse](AntiAbuse.md#anti-abuse)
  * [Flood control](AntiAbuse.md#flood-control)
    * [Message flood](AntiAbuse.md#message-flood)
    * [Join flood](AntiAbuse.md#join-flood)
    * [Enter key abuse](AntiAbuse.md#enter-key-abuse)
    * [Nick flood](AntiAbuse.md#nick-flood)
  * [Anti-away/Nick-control](AntiAbuse.md#anti-awaynick-control)
  * [Anti-auto-rejoin control](AntiAbuse.md#anti-auto-rejoin-control)
  * [Opping/Deopping](AntiAbuse.md#oppingdeopping)
<!-- md-toc-end -->
<!-- md-toc-begin -->
* [Virtual Machine](VirtualMachine.md#virtual-machine)
  * [About](VirtualMachine.md#about)
  * [Creating a new virtual machine](VirtualMachine.md#creating-a-new-virtual-machine)
  * [Configuring the virtual machine](VirtualMachine.md#configuring-the-virtual-machine)
  * [Installing Linux in the virtual machine](VirtualMachine.md#installing-linux-in-the-virtual-machine)
  * [Configuring Linux for PBot Communication](VirtualMachine.md#configuring-linux-for-pbot-communication)
  * [Hardening the PBot virtual machine](VirtualMachine.md#hardening-the-pbot-virtual-machine)
<!-- md-toc-end -->
