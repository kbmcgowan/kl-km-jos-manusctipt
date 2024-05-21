// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}

//#assert(sys.version.at(1) >= 11 or sys.version.at(0) > 0, message: "This template requires Typst Version 0.11.0 or higher. The version of Quarto you are using uses Typst version is " + str(sys.version.at(0)) + "." + str(sys.version.at(1)) + "." + str(sys.version.at(2)) + ". You will need to upgrade to Quarto 1.5 or higher to use apaquarto-typst.")

// counts how many appendixes there are
#let appendixcounter = counter("appendix")
// make latex logo
// https://github.com/typst/typst/discussions/1732#discussioncomment-6566999
#let TeX = style(styles => {
  set text(font: ("New Computer Modern", "Times", "Times New Roman"))
  let e = measure("E", styles)
  let T = "T"
  let E = text(1em, baseline: e.height * 0.31, "E")
  let X = "X"
  box(T + h(-0.15em) + E + h(-0.125em) + X)
})
#let LaTeX = style(styles => {
  set text(font: ("New Computer Modern", "Times", "Times New Roman"))
  let a-size = 0.66em
  let l = measure("L", styles)
  let a = measure(text(a-size, "A"), styles)
  let L = "L"
  let A = box(scale(x: 105%, text(a-size, baseline: a.height - l.height, "A")))
  box(L + h(-a.width * 0.67) + A + h(-a.width * 0.25) + TeX)
})

#let firstlineindent=0.5in

// documentmode: man
#let man(
  title: none,
  runninghead: none,
  margin: (x: 1in, y: 1in),
  paper: "us-letter",
  font: ("Times", "Times New Roman"),
  fontsize: 12pt,
  leading: 18pt,
  spacing: 18pt,
  firstlineindent: 0.5in,
  toc: false,
  lang: "en",
  cols: 1,
  doc,
) = {

  set page(
    paper: paper,
    margin: margin,
    header-ascent: 50%,
    header: grid(
      columns: (9fr, 1fr),
      align(left)[#upper[#runninghead]],
      align(right)[#counter(page).display()]
    )
  )


 
if sys.version.at(1) >= 11 or sys.version.at(0) > 0 {
  set table(    
    stroke: (x, y) => (
        top: if y <= 1 { 0.5pt } else { 0pt },
        bottom: .5pt,
      )
  )
}
  set par(
    justify: false, 
    leading: leading,
    first-line-indent: firstlineindent
  )

  // Also "leading" space between paragraphs
  set block(spacing: spacing, above: spacing, below: spacing)

  set text(
    font: font,
    size: fontsize,
    lang: lang
  )

  show link: set text(blue)

  show quote: set pad(x: 0.5in)
  show quote: set par(leading: leading)
  show quote: set block(spacing: spacing, above: spacing, below: spacing)
  // show LaTeX
  show "TeX": TeX
  show "LaTeX": LaTeX

  // format figure captions
  show figure.where(kind: "quarto-float-fig"): it => [
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2)[#it.supplement #it.counter.display()]
    ]
    #par[#emph[#it.caption.body]]
    #align(center)[#it.body]
  ]
  
  // format table captions
  show figure.where(kind: "quarto-float-tbl"): it => [
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2)[#it.supplement #it.counter.display()]
    ]
    #par[#emph[#it.caption.body]]
    #block[#it.body]
  ]

 // Redefine headings up to level 5 
  show heading.where(
    level: 1
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(center)
    #set text(size: fontsize)
    #it.body
  ]
  
  show heading.where(
    level: 2
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #set text(size: fontsize)
    #it.body
  ]
  
  show heading.where(
    level: 3
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #set text(size: fontsize, style: "italic")
    #it.body
  ]

  show heading.where(
    level: 4
  ): it => text(
    size: 1em,
    weight: "bold",
    it.body
  )

  show heading.where(
    level: 5
  ): it => text(
    size: 1em,
    weight: "bold",
    style: "italic",
    it.body
  )

  if cols == 1 {
    doc
  } else {
    columns(cols, gutter: 4%, doc)
  }


}
#show: document => man(
  runninghead: "Removing the disguise: the matched guise technique and listener awareness",
  document,
)


\
\
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Removing the disguise: the matched guise technique and listener awareness
]
)
]
#set align(center)
#block[
\
Kyler Laycock#super[1] and Kevin B McGowan#super[2]

#super[1];The Ohio State University

#super[2];The University of Kentucky

]
#set align(left)
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Author Note
]
)
]
#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Abstract
]
)
]
#block[
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#emph[Keywords];:

#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Removing the disguise: the matched guise technique and listener awareness
]
)
]
= Introduction
<introduction>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
A great deal of attention has been paid in the phonetics and sociophonetics literatures to the perception of the voiceless fricatives \[ʃ\] and \[s\] in English. To a first approximation, these fricatives differ in the distance between the point of lingual articulation and the teeth, which give them their characteristic sibilance Shadle \(#link(<ref-shadle1991>)[1991];). English \[s\] has a short resonating chamber behind the teeth; it is typically produced by holding the tongue blade near enough to the alveolar ridge to cause turbulent airflow. English \[ʃ\] has a comparatively larger resonating chamber; it is typically produced with a more posterior, palato-alveolar tongue position and lip rounding both of which serve to reinforce this posteriority. But listeners do not perceive via {++this type of++}{\>\>KM\<\<} first approximation{++; we are sensitive to fine phonetic details far beyond these gross, categorical, differences++}{\>\>KM\<\<}. Indeed, these two fricatives have been exciting to researchers precisely because of the sensitivity listeners bring to their perception and how that perception interacts with both linguistic and social knowledge.

== Coarticulatory and Social Information Influence \[ʃ\]-\[s\] perception
<coarticulatory-and-social-information-influence-ʃ-s-perception>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
{\>\>KL: ok, this is the specific section the editors didn’t like I think vis-a-vis "rewriting the introduction to state more strongly why this study is important to sociolinguistics, and not mainly interesting to cognitive linguists"\<\<} Listeners are sensitive to articulatory mismatches between the fricatives \[ʃ\]-\[s\] and neighboring sounds. Whalen \(#link(<ref-whalen1984>)[1984];) conducted a series of experiments to investigate listeners’ responses to articulatory mismatches in synthetic speech. Overall, the result of these investigations was that subcategorical phonetic mismatches slow phonetic judgments. In onset position, in isolation, or in coda position, misleading coarticulatory information inhibited reaction times. Listeners, Whalen cautions in the conclusion, are sensitive to articulatory patterns that are below the level of conscious awareness and not available to direct experimenter scrutiny. While listeners will readily fill-in missing or ambiguous information, the presence of actively #emph[conflicting] articulatory information is inhibitory.

A commonly used methodology involves the creation of synthetic fricative continua. These continua have endpoints in prototypical examples of \[ʃ\] and \[s\] with some number of equal-sized acoustic steps generated, synthesized, or even mixed between these. Somewhere in the middle of such a continuum will be fricative-like noise that is ambiguous as to category membership: not clearly a \[ʃ\] and not clearly an \[s\]. paired a continuum from \[ʃ\] \(2.9 kHz) to \[s\] \(4.4 kHz) with synthetic \[æ\] vowels to form CV pairs. May found that listeners perceived a higher proportion of the fricative continuum as \[ʃ\] when paired with vowel stimuli from a smaller vocal tract. The logic here is that smaller resonating chambers between the lingual articulation and teeth will have a higher mean frequency than larger resonating chambers. Listeners’ use of apparent vocal tract size in perception reflect their knowledge of this variation \(#link(<ref-munson2011>)[Munson, 2011];).

Mann and Repp \(#link(<ref-MannRepp1980>)[1980];) replicated this finding, extending it to natural productions of vowels spoken by a male or female-identified talker. Similar to May’s results with simulated vocal tract size, Mann & Repp found a higher proportion of the fricative continuum was heard as \[ʃ\] when paired with the speech of the female talker. This early work, like others of the period \(#link(<ref-ohala1984>)[Ohala, 1984];), theorized size as being a relatively deterministic feature of talker sexual dimorphism. One consequence of this view is that gender-related variation in the speech signal is considered mechanistic, universal, and following from purely physical laws. Vocal tract size is presumably not available for individual performance and so listener knowledge of this variation can be correspondingly simple. Vocal tract size may influence perception, but it does so implicitly, automatically, and below the level of introspective awareness.

{++ Mann and Repp \(#link(<ref-MannRepp1980>)[1980];) also replicated and extended previous work \(#link(<ref-kunisakifujisaki1977>)[Kunisaki & Fujisaki, 1977];; #link(<ref-whalen1981>)[Whalen, 1981];) demonstrating that listeners report hearing more of the synthetic fricative continuum as \[s\] when followed by a rounded vowel quality such as English \[u\] than when followed by an unrounded quality such as \[i\] or \[a\]. Listeners experience the fricative continuum differently in the presence of anticipatory coarticulation. The presence of nasal coarticulation on a vowel similarly allows listeners to make a lexical decision between words like #emph[bend] and #emph[bed] as soon as that information is present in the acoustic signal \(#link(<ref-beddormcgowanbolandcoetzeebrasher2013>)[Beddor et al., 2013];, #link(<ref-beddorcoetzeestylermcgowanboland2018>)[2018];). Mann & Repp’s participants in this study experienced auditory evidence of posteriority in the ambiguous portion of the fricative continuum as the presence of coarticulation with a following rounded vowel. As with vocal tract length, above, the behavioral result was a shift in the listeners’ fricative category boundary toward \[s\]. ++}{\>\>KM: clarifying and putting this back at least for now.\<\<}

Strand and Johnson \(#link(<ref-strandJohnson1996>)[1996];) conducted a pair of experiments investigating the influence of purported gender of a talker on the perception of the \[ʃ\]-\[s\] boundary. In their experiment 1, listeners heard a \[ʃ\]-\[s\] continuum paired with voices previously normed as prototypical female, non-prototypical female, non-prototypical male, and prototypical male voices. The result replicates Mann and Repp \(#link(<ref-MannRepp1980>)[1980];) and extends it to show that the influence of a gendered voice correlates with the protypicality of that voice \(exp1). They then extend this research to show that presenting listeners with prototypically-gendered videos of their purported talker can, again, shift perceptions of the \[ʃ\]-\[s\] such that listeners report hearing a higher proportion of the continuum as \[ʃ\] when watching a female talker and a higher proportion of \[s\] when watching a male talker. The AV condition of their experiment 2 is reminiscent of McGurk and MacDonald \(#link(<ref-McGurkMacDonald1976>)[1976];) and is presented in that context. A striking feature of the McGurk Effect is its automaticity; participants can not choose to perceive the two components of a fused percept independently. It is unclear from Strand and Johnson \(#link(<ref-strandJohnson1996>)[1996];) and subsequent work whether the perceptual influence of visually-presented social information is implicit and automatic, like vocal tract size, the McGurk effect, etc., or whether the effect disappears when listeners are aware of the guise manipulation.

This is an incomplete sample of the literature on the perception of these fricatives. We hope, however, that the message is clear that even when arriving at a purely linguistic percept, listeners’ judgments depend on a rich constellation of evidence and expectation. Vocal tract size, formant transitions, following vowel quality \(#link(<ref-MannRepp1980>)[Mann & Repp, 1980];), and coarticulatory cues, along with the acoustic properties of the fricative itself, can all shape how listeners report experiencing that fricative. Rather than relying on a single, invariant, phonetic cue, listeners take the entire fricative and context into account Whalen \(#link(<ref-whalen1991>)[1991];).

{#strike[One imagines\~\> It is conceivable that];} {\>\>KM\<\<} such exquisite sensitivity to the phonetic cues conveying linguistic category membership might restrict language users’ freedom to communicate and perceive social information via the same phonetic signal. This would be the prediction of a phonetic theory in which linguistic information and social information battle for control of the air waves –where listeners must normalize away social variation to recover linguistic information. Instead, with these fricatives, at least, we can observe the opposite. The fricatives /ʃ/ and /s/ often carry social meaning \(#link(<ref-mackMunson2012b>)[Mack & Munson, 2012];; #link(<ref-podesvakajino2014>)[Podesva & Kajino, 2014];) with /s/ being "perhaps the most iconic phonetic variable in the field" \(#link(<ref-calder2018>)[Calder, 2018];). The implication is that the social and linguistic meanings of particular phonetic cues are not in competition with one another.

== Phonetics, Speech Perception, and the Social-Construction of Gender
<phonetics-speech-perception-and-the-social-construction-of-gender>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
La Palma is one of the west most islands in the Volcanic Archipelago of the Canary Islands \(#link(<fig-map>)[Figure~1];).

#link(<fig-spatial-plot>)[Figure~2] shows the location of recent Earthquakes on La Palma.

== Data & Methods
<sec-data-methods>
== Conclusion
<conclusion>
#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
References
]
)
]
#set par(first-line-indent: 0in, hanging-indent: 0.5in)
#block[
#block[
Beddor, P. S., Coetzee, A. W., Styler, W., McGowan, K. B., & Boland, J. E. \(2018). The time course of individuals’ perception of coarticulatory information is linked to their production: Implications for sound change. #emph[Language];, #emph[94];\(4), 931–968.

] <ref-beddorcoetzeestylermcgowanboland2018>
#block[
Beddor, P. S., McGowan, K. B., Boland, J. E., Coetzee, A. W., & Brasher, A. \(2013). The time course of perception of coarticulation. #emph[The Journal of the Acoustical Society of America];, #emph[133];\(4), 2350–2366.

] <ref-beddormcgowanbolandcoetzeebrasher2013>
#block[
Calder, J. \(2018). From “gay lisp” to “fierce queen”: The sociophonetics of sexuality’s most iconic variable. In K. Hall & R. Barrett \(Eds.), #emph[The oxford handbook of language and sexuality] \(pp. 1–23).

] <ref-calder2018>
#block[
Fant, G. \(1960). #emph[Acoustic theory of speech production];. Mouton.

] <ref-fant1960>
#block[
Kunisaki, O., & Fujisaki, H. \(1977). On the influence of context upon perception of voiceless fricative consonants. #emph[Annual Bulletin];, #emph[11];, 85–91.

] <ref-kunisakifujisaki1977>
#block[
Mack, S., & Munson, B. \(2012). The association between/s/quality and perceived sexual orientation of men’s voices: Implicit and explicit measures. #emph[Journal of Phonetics];, #emph[40];\(1), 198–212.

] <ref-mackMunson2012b>
#block[
Mann, V. A., & Repp, B. H. \(1980). Influence of vocalic context on perception of the \[ʃ\]-\[s\] distinction. #emph[Perception & Psychophysics];, #emph[28];\(3), 213–228.

] <ref-MannRepp1980>
#block[
McGurk, H., & MacDonald, J. \(1976). Hearing lips and seeing voices. #emph[Nature];, #emph[264];, 746–748.

] <ref-McGurkMacDonald1976>
#block[
Munson, B. \(2011). The influence of actual and imputed talker gender on fricative perception, revisited \(l). #emph[The Journal of the Acoustical Society of America];, #emph[130];\(5), 2631–2634.

] <ref-munson2011>
#block[
Ohala, J. J. \(1984). An ethological perspective on common cross-language utilization of F₀ of voice. #emph[Phonetica];, #emph[41];\(1), 1–16.

] <ref-ohala1984>
#block[
Podesva, R. J., & Kajino, S. \(2014). Sociophonetics, gender, and sexuality. #emph[The Handbook of Language, Gender, and Sexuality];, 103–122.

] <ref-podesvakajino2014>
#block[
Shadle, C. H. \(1991). The effect of geometry on source mechanisms of fricative consonants. #emph[Journal of Phonetics];, #emph[19];\(3-4), 409–424.

] <ref-shadle1991>
#block[
Strand, E. A. \(1999). Uncovering the role of gender stereotypes in speech perception. #emph[Journal of Language and Social Psychology];, #emph[18];\(1), 86–100.

] <ref-strand1999>
#block[
Strand, E. A., & Johnson, K. \(1996). Gradient and visual speaker normalization in the perception of fricatives. #emph[KONVENS];, 14–26.

] <ref-strandJohnson1996>
#block[
Whalen, D. H. \(1981). Effects of vocalic formant transitions and vowel quality on the english \[s\]–\[š\] boundary. #emph[The Journal of the Acoustical Society of America];, #emph[69];\(1), 275–282.

] <ref-whalen1981>
#block[
Whalen, D. H. \(1984). Subcategorical phonetic mismatches slow phonetic judgments. #emph[Perception & Psychophysics];, #emph[35];, 49–64.

] <ref-whalen1984>
#block[
Whalen, D. H. \(1991). Perception of the english/s/–//distinction relies on fricative noises and transitions, not on brief spectral slices. #emph[The Journal of the Acoustical Society of America];, #emph[90];\(4), 1776–1785.

] <ref-whalen1991>
] <refs>
#set par(first-line-indent: 0.5in, hanging-indent: 0in)
#figure([
#box(width: 1920.0pt, image("images/la-palma-map.png"))
], caption: figure.caption(
position: top, 
[
Map of La Palma
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-map>


#pagebreak(weak: true)
#block[
#block[
#block[
#figure([
#box(width: 672.0pt, image("index_files/figure-typst/notebooks-explore-earthquakes-fig-spatial-plot-output-1.png"))
], caption: figure.caption(
position: top, 
[
Locations of earthquakes on La Palma since 2017
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-spatial-plot>


]
]
]
#pagebreak(weak: true)




<div id="criticnav">
<ul>
<li id="markup-button">Markup</li>
<li id="original-button">Original</li>
<li id="edited-button">Edited</li>
</ul>
</div>

<script type="text/javascript">
  function critic() {

      $('.content').addClass('markup');
      $('#markup-button').addClass('active');
      $('ins.break').unwrap();
      $('span.critic.comment').wrap('<span class="popoverc" /></span>');
      $('span.critic.comment').before('&#8225;');
  }

  function original() {
      $('#original-button').addClass('active');
      $('#edited-button').removeClass('active');
      $('#markup-button').removeClass('active');

      $('.content').addClass('original');
      $('.content').removeClass('edited');
      $('.content').removeClass('markup');
  }

  function edited() {
      $('#original-button').removeClass('active');
      $('#edited-button').addClass('active');
      $('#markup-button').removeClass('active');

      $('.content').removeClass('original');
      $('.content').addClass('edited');
      $('.content').removeClass('markup');
  } 

  function markup() {
      $('#original-button').removeClass('active');
      $('#edited-button').removeClass('active');
      $('#markup-button').addClass('active');

      $('.content').removeClass('original');
      $('.content').removeClass('edited');
      $('.content').addClass('markup');
  }

  var o = document.getElementById("original-button");
  var e = document.getElementById("edited-button");
  var m = document.getElementById("markup-button");

  window.onload = critic();
  o.onclick = original;
  e.onclick = edited;
  m.onclick = markup;
</script>
