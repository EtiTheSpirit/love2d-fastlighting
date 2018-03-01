# Fastlighting
A fast, shader-based lighting engine for LÖVE2D - http://love2d.org/

# Functionality
This lighting engine uses a quick, mostly-acceptable, and modular method of creating dynamic lighting within LOVE2D that has precision down to the pixel.

# Performance
Performance for Fastlighting is a bit iffy in terms of being a crappy lighting system vs. a top-of-the-line system. Personal tests conclude that:

- Performance is outstanding with **1 to 10 lights** and **1 to 6 occlusion areas** (Est. 250-350 FPS)
- Performance is decent with **11 to 15 lights** and **6 to 9 occlusion areas** (Est. 100-140 FPS)
- Performance is average with **16 to 18 lights** and **10 to 12 occlusion areas** (Est. 60 FPS)
- Performance becomes poor with any more than that.

Performance is also influenced by the radius of the light. Lights / occlusion areas with larger areas tend to cause more of a performance impact.
