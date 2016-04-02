# queueup

A browser-based music player for trees of MP3s

## Usage:

```bash
git clone https://github.com/drench/queueup.git &&
cd queueup &&
gem install taglib-ruby &&
./queueup /Path/To/Some/Directory/With/MP3s &&
(cd /Path/To/Some/Directory/With/MP3s && ruby -run -e httpd . -p 8000) &&
open http://localhost:8000/
```
