import 'dart:convert';

List<PricingPlan> pricingPlanFromJson(String str) =>
    List<PricingPlan>.from(json.decode(str).map((x) => PricingPlan.fromJson(x)));

String pricingPlanToJson(List<PricingPlan> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PricingPlan {
  final int id;
  final String date;
  final String dateGmt;
  final Guid guid;
  final String modified;
  final String modifiedGmt;
  final String slug;
  final String status;
  final String type;
  final String link;
  final Title title;
  final String template;
  final List<dynamic> acf;
  final String yoastHead;
  final YoastHeadJson? yoastHeadJson;
  final String planType;
  final String freePlan;
  final String fmPrice;
  final String fmDescription;
  final String fmBooking;
  final String listingContent;
  final String pricing;
  final String location;
  final String category;
  final String phone;
  final String email;
  final Links links;

  PricingPlan({
    required this.id,
    required this.date,
    required this.dateGmt,
    required this.guid,
    required this.modified,
    required this.modifiedGmt,
    required this.slug,
    required this.status,
    required this.type,
    required this.link,
    required this.title,
    required this.template,
    required this.acf,
    required this.yoastHead,
    required this.yoastHeadJson,
    required this.planType,
    required this.freePlan,
    required this.fmPrice,
    required this.fmDescription,
    required this.fmBooking,
    required this.listingContent,
    required this.pricing,
    required this.location,
    required this.category,
    required this.phone,
    required this.email,
    required this.links,
  });

  factory PricingPlan.fromJson(Map<String, dynamic> json) => PricingPlan(
        id: json["id"],
        date: json["date"],
        dateGmt: json["date_gmt"],
        guid: Guid.fromJson(json["guid"]),
        modified: json["modified"],
        modifiedGmt: json["modified_gmt"],
        slug: json["slug"],
        status: json["status"],
        type: json["type"],
        link: json["link"],
        title: Title.fromJson(json["title"]),
        template: json["template"],
        acf: List<dynamic>.from(json["acf"].map((x) => x)),
        yoastHead: json["yoast_head"],
        yoastHeadJson: json["yoast_head_json"] != null
            ? YoastHeadJson.fromJson(json["yoast_head_json"])
            : null,
        planType: json["plan_type"],
        freePlan: json["free_plan"],
        fmPrice: json["fm_price"],
        fmDescription: json["fm_description"],
        fmBooking: json["_fm_booking"],
        listingContent: json["_listing_content"],
        pricing: json["_pricing"],
        location: json["_location"],
        category: json["_category"],
        phone: json["_phone"],
        email: json["_email"],
        links: Links.fromJson(json["_links"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "date": date,
        "date_gmt": dateGmt,
        "guid": guid.toJson(),
        "modified": modified,
        "modified_gmt": modifiedGmt,
        "slug": slug,
        "status": status,
        "type": type,
        "link": link,
        "title": title.toJson(),
        "template": template,
        "acf": List<dynamic>.from(acf.map((x) => x)),
        "yoast_head": yoastHead,
        "yoast_head_json": yoastHeadJson?.toJson(),
        "plan_type": planType,
        "free_plan": freePlan,
        "fm_price": fmPrice,
        "fm_description": fmDescription,
        "_fm_booking": fmBooking,
        "_listing_content": listingContent,
        "_pricing": pricing,
        "_location": location,
        "_category": category,
        "_phone": phone,
        "_email": email,
        "_links": links.toJson(),
      };
}

class Guid {
  final String rendered;

  Guid({required this.rendered});

  factory Guid.fromJson(Map<String, dynamic> json) =>
      Guid(rendered: json["rendered"]);

  Map<String, dynamic> toJson() => {"rendered": rendered};
}

class Title {
  final String rendered;

  Title({required this.rendered});

  factory Title.fromJson(Map<String, dynamic> json) =>
      Title(rendered: json["rendered"]);

  Map<String, dynamic> toJson() => {"rendered": rendered};
}

class Links {
  final List<Self> self;
  final List<Self> collection;
  final List<Self> about;

  Links({
    required this.self,
    required this.collection,
    required this.about,
  });

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        self: List<Self>.from(json["self"].map((x) => Self.fromJson(x))),
        collection:
            List<Self>.from(json["collection"].map((x) => Self.fromJson(x))),
        about: List<Self>.from(json["about"].map((x) => Self.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "self": List<dynamic>.from(self.map((x) => x.toJson())),
        "collection": List<dynamic>.from(collection.map((x) => x.toJson())),
        "about": List<dynamic>.from(about.map((x) => x.toJson())),
      };
}

class Self {
  final String href;

  Self({required this.href});

  factory Self.fromJson(Map<String, dynamic> json) =>
      Self(href: json["href"]);

  Map<String, dynamic> toJson() => {"href": href};
}

/// You can expand this based on what fields you need
class YoastHeadJson {
  final String title;

  YoastHeadJson({required this.title});

  factory YoastHeadJson.fromJson(Map<String, dynamic> json) =>
      YoastHeadJson(title: json["title"]);

  Map<String, dynamic> toJson() => {"title": title};
}
