// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

class Faq {
  String? title;
  List<Session>? session;

  Faq({this.title, this.session});

  Faq.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    if (json['session'] != null) {
      session = <Session>[];
      json['session'].forEach((v) {
        session!.add(Session.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    if (session != null) {
      data['session'] = session!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Session {
  String? title;
  String? content;

  Session({this.title, this.content});

  Session.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['content'] = content;
    return data;
  }
}
