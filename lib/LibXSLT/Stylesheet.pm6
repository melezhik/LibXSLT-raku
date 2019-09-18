unit class LibXSLT::Stylesheet;

use LibXSLT::Native;
use LibXSLT::TransformContext;

use LibXML::Config;
use LibXML::Document;
use LibXML::Native;
use LibXML::Native::Defs :CLIB;

use NativeCall;

constant config = LibXML::Config;

has $.input-callbacks is rw = config.input-callbacks;
multi method input-callbacks is rw { $!input-callbacks }
multi method input-callbacks($!input-callbacks) {}

has xsltStylesheet $!native handles <media-type output-method>;
method native { $!native }

submethod DESTROY {
    .Free with $!native;
}

sub generic-error-cb($ctx, Str $fmt, |args) {
    CATCH { default { warn "error handling XSLT error: $_" } }
    $*XSLT-CONTEXT.generic-error($fmt, |args);
}

method !try(&action) {
    my $*XSLT-CONTEXT = LibXML::ErrorHandler.new;

    xsltTransformContext.SetGenericErrorFunc: &generic-error-cb;

    my @input-contexts = .activate()
        with $.input-callbacks;

    &*chdir(~$*CWD);
    my $rv := &action();

    .deactivate with $.input-callbacks;
    .flush-errors for @input-contexts;
    $*XSLT-CONTEXT.flush-errors;

    $rv;
}

proto method parse-stylesheet(|c) {
    with self {return {*}} else { self.new.parse-stylesheet(|c) }
}

multi method parse-stylesheet(LibXML::Document:D :$doc! --> LibXSLT::Stylesheet) {
    .Free with $!native;
    self!try: {
        my $doc-copy = $doc.native.copy: :deep;
        $!native = xsltParseStylesheetDoc($doc-copy);
    }
    self;
}

multi method parse-stylesheet(Str:D() :$file! --> LibXSLT::Stylesheet) {
    .Free with $!native;
    self!try: {
        $!native = xsltParseStylesheetFile($file);
    }
    self;
}

multi method parse-stylesheet(LibXML::Document:D $doc --> LibXSLT::Stylesheet) {
    self.parse-stylesheet: :$doc;
}

multi method transform(LibXML::Document:D :$doc!, *%params --> LibXML::Document) {
    my LibXSLT::TransformContext $ctx .= new: :$doc, :stylesheet(self), :$!input-callbacks;
    my CArray[Str] $params .= new(|%params.kv, Str);
    my xmlDoc $result;
    $ctx.try: {
        $result = $!native.transform($doc.native, $ctx.native, $params);
    }
    (require LibXSLT::Document).new: :native($result), :xslt(self);
}

multi method transform(:$file!, |c --> LibXML::Document) {
    my LibXML::Document:D $doc .= parse: :$file;
    self.transform: :$doc, |c;

}
