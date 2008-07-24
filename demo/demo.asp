<!DOCTYPE html>
<html>
<body>
<script language="javascript" src="../lib/prototype.js.asp" runat="server">
</script>
<!-- Demo of the fb() function -->
<script language="javascript" src="../lib/fb.js.asp" runat="server"></script>
<script language="javascript" runat="server">
  fb('Hello World');
  fb('Hello World 2');

  fb('Log message', fb.LOG);
  fb('Info message', fb.INFO);
  fb('Warn message', fb.WARN);
  fb('Error message', fb.ERROR);

  fb('Message with label','Label', fb.LOG);

  try {
    throw new Error('Test Exception');
  } catch(e) {
    fb(e);
  }
  // Will show only in "Server" tab for the request
  fb({ a : 1, b : 2, c : 3 }, 'Some object', fb.DUMP);
  fb({ d : 1, e : 2, f : 3 }, 'Another object', fb.DUMP);
</script>
<!-- Same type of thing, but for the console functions -->
<script language="javascript" src="../lib/console.js.asp" runat="server">
</script>
<script language="javascript" runat="server">
  console.log('Hello World');
  console.log('Hello World 2');

  console.log('Log message');
  console.info('Info message');
  console.warn('Warn message');
  console.error('Error message');

  console.log({ a : 1, b : 2, c : 3});

  try {
    throw new Error('Test Exception');
  } catch(e) {
    console.error(e);
  }
</script>
</body>
</html>
