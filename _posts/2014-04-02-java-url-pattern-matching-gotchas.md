---
layout: post
title: Java URL Pattern Matching Gotchas
categories: [security]
tags: [java]
description: An analysis of Java web container pattern matching for servlets and spring
---

Many security features in Java rely on endpoint pattern matching which allow
for URL pattern matching bypasses if not careful. Additionally Spring MVC and
Spring Security together introduces are a few gotcha's during implementation.

## Security Constraint Matching

The most basic form of authentication within Java is using the
`<security-constraint/>` tag. The following is an example constraint
restricting access to /basic endpoint using Basic auth.

{% highlight xml %}
<!-- Basic Security -->
<security-constraint>
    <web-resource-collection>
        <web-resource-name>baisc auth
restriction</web-resource-name>
        <url-pattern>/basic</url-pattern>
    </web-resource-collection>
    …
</security-constraint>
{% endhighlight %}

All official Java documentation uses the url-pattern `/*`, though details for
`<url-pattern/>` can be found in section 12.2 of the 3.0 servlet
specification. The following details mapping test-cases which have standard
Java servlets mapped to /basic

| Servlet Map | `<url-pattern/>` | Request    | Response Code |
|-------------|------------------|------------|---------------|
| /basic      | `/basic*`        | `GET /basic` | <span style="color:#f00">200</span> |
| /basic      | `/basic/`        | `GET /basic` | <span style="color:#f00">200</span> |
| /basic      | `/basic/*`       | `GET /basic` | <span style="color:#396">401</span> |
| /basic      | `/basic`         | `GET /basic` | <span style="color:#396">401</span> |


Wild cards do not function as expected, and only by leaving out extensions for
a literal matching or using `/*` can servlet patterns be correctly matched.

## Security Constraints with Spring MVC

However if, for example, using the &lt;security-restraint/&gt; function to
protect Spring MVC controllers the following is observed:

| MVC Map   | `<url-pattern/>` | Request          | Response Code |
|-----------|------------------|------------------|---------------|
| /mvcpoint | `/mvcpoint*`     | `GET /mvcpoint`  | <span style="color:#f00">200</span> |
| /mvcpoint | `/mvcpoint/`     | `GET /mvcpoint`  | <span style="color:#f00">200</span> |
| /mvcpoint | `/mvcpoint/*`    | `GET /mvcpoint.` | <span style="color:#f00">200</span> |
| /mvcpoint | `/mvcpoint`      | `GET /mvcpoint/` | <span style="color:#f00">200</span> |
| /mvcpoint | `/mvcpoint*/*`   | `GET /mvcpoint`  | <span style="color:#f00">200</span> |

The lesson here is never use standard `<security-constraint/>` methods when
attempting to restrict endpoints which are not servlets. We will touch on the
use of the . below.
<h2>Spring Security Pattern Matching</h2>
Security interceptors used by Spring Security use ANT pattern matching. This
type of matching is different from Regex. See the <a
href="https://ant.apache.org/manual/dirtasks.html#patterns">ANT documentation
on patterns</a> for specifics.

The following is an example of a Spring Security URL pattern constraint:

{% highlight xml %}
<http>
    <intercept-url pattern="/welcome*" access="ROLE_USER" />
    <http-basic />
</http>
{% endhighlight %}
The following is a test table showing various patterns, and their bypass:

| MVC Map   | <intercept-url/> | Request        | Response Code |
|-----------|------------------|----------------|---------------|
| /mvcpoint | /mvcpoint*       | GET /mvcpoint/ | 200           |
| /mvcpoint | /mvcpoint/       | GET /mvcpoint  | 200           |
| /mvcpoint | /mvcpoint/*      | GET /mvcpoint  | 200           |
| /mvcpoint | /mvcpoint**      | GET /mvcpoint/ | 200           |
| /mvcpoint | /mvcpoint/**     | GET /mvcpoint. | 200           |
| /mvcpoint | /mvcpoint        | GET /mvcpoint. | 200           |
| /mvcpoint | /mvcpoint*/*     | GET /mvcpoint  | 200           |
| /mvcpoint | /mvcpoint**/*    | GET /mvcpoint  | 200           |
| /mvcpoint | /mvcpoint*/**    | GET /mvcpoint. | 401           |

The table shows that only a single spring-security pattern (*/**) is able to
secure against unauthorized access. To discover why, we must dig deeper.
<h2>Spring MVC with Spring Security</h2>
The problem arises in spring-mvc and its handling of extensions. We are able to
supply an incomplete extension (note the trailing . on the requests) to
spring-security which results in the bypass of the rule. When the incomplete
extension gets to spring-mvc however, the incomplete extension is treated as
erroneous and automatically returns the original mapping.

{% highlight java %}
private String getMatchingPattern(String pattern, String lookupPath) {
    if (pattern.equals(lookupPath)) {
        return pattern;
    }
    if (this.useSuffixPatternMatch) {
        if (useSmartSuffixPatternMatch(pattern, lookupPath)) {
            for (String extension : this.fileExtensions) {
                if (this.pathMatcher.match(pattern + extension, lookupPath)) {
                    return pattern + extension;
                }
            }
        }
        else {
            boolean hasSuffix = pattern.indexOf('.') != -1;
            if (!hasSuffix &amp;&amp; this.pathMatcher.match(pattern + ".*",
lookupPath)) {
                return pattern + ".*";
            }
        }
    }
    if (this.pathMatcher.match(pattern, lookupPath)) {
        return pattern;
    }
    boolean endsWithSlash = pattern.endsWith("/");
    if (this.useTrailingSlashMatch) {
        if (!endsWithSlash &amp;&amp; this.pathMatcher.match(pattern + "/",
lookupPath)) {
            return pattern +"/";
        }
    }
    return null;
}

private boolean useSmartSuffixPatternMatch(String pattern, String lookupPath) {
    return (!this.fileExtensions.isEmpty() &amp;&amp; lookupPath.indexOf('.')
!= -1) ;
}
{% endhighlight %}
org.springframework.web.servlet.mvc.condition.PatternsRequestCondition.java
starting at line 223

The code, upon being passed to spring mvc as such
<pre class="brush:java">getMatchingPattern("/basic2", "/basic2.")</pre>
Will end up in the following block because of useSmartSuffixPatternMatch
evaluating to false.
<pre class="brush:java">boolean hasSuffix = pattern.indexOf('.') != -1;
if (!hasSuffix &amp;&amp; this.pathMatcher.match(pattern + ".*", lookupPath)) {
    return pattern + ".*";
}</pre>
This results in the return of "/basic2.*" due to the pathMatcher automatically
appending .* to the pattern. In the end this function will find the correct
controller mapping in spite of the added period.
<h2>Summary</h2>
<ul>
  <li>Only protect servlets with the &lt;security-constraint/&gt; element</li>
  <li>Always use /* when defining &lt;security-constraint/&gt;  patterns</li>
  <li>Always use */** when defining &lt;intercept-url/&gt; patterns</li>
</ul>
