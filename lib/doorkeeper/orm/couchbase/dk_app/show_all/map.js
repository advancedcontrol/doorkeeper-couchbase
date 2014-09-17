function (doc, meta)
{
  if(doc.type === 'dk_app') {
    emit(null, [doc.name, doc.secret, doc.redirect_uri]);
  }
}
