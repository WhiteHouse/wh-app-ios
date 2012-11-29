# White House for iOS mobile application

A native iOS app designed to fetch, cache, and display multiple feeds
containing articles, photos, and live and on demand video. These are
displayed in a web view. Includes support for push notifications.
 
This application is under active development and will continue to be
modified and improved over time.
 
## Goals

By releasing the source code for this app we hope to empower other
governments and organizations to build and release mobile apps to
engage their own citizens and constituencies. In addition, public
review and contribution to the application's code base will help
strengthen and improve the app.
 
## Requirements

1. iPhone, iPad, iPod Touch iOS version 5.1 or later
2. RSS feeds for content to be aggregated and displayed by the app
     
## Usage

Mobile developers will be able to configure the application to
retrieve and display content from arbitrary RSS feeds. The developer
will be able to configure the app to receive push
notifications. Placeholder assets may be replaced to customize the
app's look and feel.

Building the app requires the iOS 5.1 SDK or higher.

This app makes use of several libraries in source, binary, and
submodule form. All libraries live in the `libs/` directory.

The following sections describe all of the libraries and any steps
necessary to initialize them.

### Source

The following libraries are directly included as source code:

* [CustomBadge][]
* [DTCustomColoredAccessory][]
* [Zepto.js][]
* [Underscore.js][]

### Submodules

The following libraries are included as submodules:

* [SVPullToRefresh][]
* [Nimbus][]
* [Facebook SDK for iOS][fb]

To intialize submodules, run:

    git submodule update --init

To build Facebook, `cd` into `libs/facebook` and run
`./scripts/build_facebook_ios_sdk_static_lib.sh`. This will build the
static library used by the app.

### Binary Libraries

The following libraries must be downloaded and installed manually:

* [libUAirship][] - Urban Airship library for iOS
* [Google Analytics SDK for iOS][ga]

To install Urban Airship, download the SDK and place the entire
`Airship` directory inside of `libs/`.

To install Google Analytics, download the SDK and place the entire
`Google Analytics SDK` directory inside of `libs/`.

### Feeds

The app's content is pulled in from RSS feeds.

A thumbnail image is displayed in feed list views when the source 
feed <item> has a <media:thumbnail> element. The "width" attribute 
is required; the parser currently ignores thumbnail elements with no width. 

Example:

    <item>
         <media:thumbnail url="http://www.whitehouse.gov/example-image-320px.jpg" width="320"/>
         <media:thumbnail url="http://www.whitehouse.gov/example-image-640px.jpg" width="640"/>
    </item>

The optimal size for display is chosen depending on the context (e.g. 640px 
for article feeds on the iPhone 4, or ~70px for photo gallery thumbnails on the 
iPhone 3GS) and screen density.

### Search

Search functionality on WhiteHouse.gov and in the White House for iOS 
mobile app relies on USASearch, a hosted site search service provided by 
the U.S. General Services Administration (GSA). Federal, state, local, 
tribal, or territorial government websites may use this service at no cost. 
For details on incorporating USASearch into .Gov sites, or for examples of 
the API and how it functions, see  [USASearch: About](http://usasearch.howto.gov/about-us)
and  [USASearch: How (and When) to Use the Search API](http://usasearch.howto.gov/post/36743437542/how-and-when-to-use-the-search-api).



NOTE: Setting up the application and configuring it for use in your
organization's context requires iOS development experience. The
application ships with a similar design to what is used in the White
House for iOS mobile application. The application ships with "white
label" placeholder assets that should be replaced by the developer.
 
## Roadmap

Have an idea or question about future features for White House for
iOS? Let us know by opening a ticket on GitHub, tweeting @WHWeb, or
via our tech feedback form: http://www.whitehouse.gov/tech/feedback.
 
## Contributing

Anyone is encouraged to contribute to the project by [forking][] and
submitting a pull request. (If you are new to GitHub, you might start
with a [basic tutorial][].)
 
By contributing to this project, you grant a world-wide, royalty-free,
perpetual, irrevocable, non-exclusive, transferable license, free of
charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished
to do so, subject to the conditions that any appropriate copyright
notices and this permission notice are included in all copies or
substantial portions of the Software.
 
All comments, messages, pull requests, and other submissions received
through official White House pages including this GitHub page are
subject to the Presidential Records Act and may be archived. Learn
more http://WhiteHouse.gov/privacy
 
## License

This project constitutes a work of the United States Government and is
not subject to domestic copyright protection under 17 USC § 105.
 
However, because the project utilizes code licensed from contributors
and other third parties, it therefore is licensed under the MIT
License.  http://opensource.org/licenses/mit-license.php.  Under that
license, permission is granted free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the conditions that any appropriate copyright notices and this
permission notice are included in all copies or substantial portions
of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



[libUAirship]: http://urbanairship.com/resources/
[ga]: https://developers.google.com/analytics/devguides/collection/ios/resources
[CustomBadge]: http://www.spaulus.com/2011/04/custombadge-2-0-retina-ready-scalable-light-reflex/
[Underscore.js]: http://underscorejs.org/
[Zepto.js]: http://zeptojs.com/
[DTCustomColoredAccessory]: http://www.cocoanetics.com/2010/10/custom-colored-disclosure-indicators/
[SVPullToRefresh]: https://github.com/samvermette/SVPullToRefresh
[fb]: https://github.com/facebook/facebook-ios-sdk
[Nimbus]: https://github.com/jverkoey/nimbus

[forking]: https://help.github.com/articles/fork-a-repo
[basic tutorial]: https://help.github.com/articles/set-up-git
