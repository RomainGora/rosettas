with Ada.Text_IO;                        use Ada.Text_IO;
with Ada.Calendar;                       use Ada.Calendar;
with Ada.Calendar.Formatting;
with Rosetta;                            use Rosetta;
with Ada.Strings.Text_Buffers;

package body Rosetta_Renderer is

   --  Removes the leading space of a string.
   function Trim_Leading_Space (S : String) return String is
   begin
      if S'Length > 0 and then S (S'First) = ' ' then
         return S (S'First + 1 .. S'Last);
      end if;
      return S;
   end Trim_Leading_Space;

   type My_Integer is new Integer
   with Put_Image => My_Put_Image;

   procedure My_Put_Image
     (Output : in out Ada.Strings.Text_Buffers.Root_Buffer_Type'Class;
      Value  : My_Integer);

   --  Redefines the 'Image attribute for My_Integer.
   procedure My_Put_Image
     (Output : in out Ada.Strings.Text_Buffers.Root_Buffer_Type'Class;
      Value  : My_Integer)
   is
     S : constant String := Integer (Value)'Image;
   begin
       Output.Put (Trim_Leading_Space (S));
   end My_Put_Image;

   --  Outputs the opening tags of the SVG document with canvas dimensions and background color.
   procedure Put_Header (Stream     : in out File_Type;
                         Width      : My_Integer := 800;
                         Height     : My_Integer := 800;
                         Background : String  := "white"
                        ) is
      XML_Header : constant String := "<?xml version=""1.0"" encoding=""UTF-8""?>";
      SVG_Open   : constant String :=
      "<svg xmlns=""http://www.w3.org/2000/svg"" version=""1.1"" " &
      "width="""  & My_Integer'Image (Width)  & """ " &
      "height=""" & My_Integer'Image (Height) & """ " &
      "viewBox=""0 0" & My_Integer'Image (Width) & My_Integer'Image (Height) & """>";
      Background_Rect : constant String :=
        "  <rect width=""100%"" height=""100%"" fill=""" & Background & """ />";
   begin
      Put_Line (Stream, XML_Header);
      Put_Line (Stream, SVG_Open);
      Put_Line (Stream, Background_Rect);
   end Put_Header;

   --  Outputs the closing part of the SVG document, including a timestamp label.
   procedure Put_Footer (Stream    : in out File_Type) is
      Date_Label : constant String := Ada.Calendar.Formatting.Image (Clock);
      Timestamp_Text : constant String :=
        "  <text x=""0"" y=""10"" fill=""#ccc"" opacity=""0.7"" " &
        "font-family=""monospace"" font-size=""10"">" &
        Date_Label & "</text>";
      SVG_Close : constant String := "</svg>";
   begin
      Put_Line (Stream, Timestamp_Text);
      Put_Line (Stream, SVG_Close);
   end Put_Footer;

   --  Outputs a grid of lines over the SVG canvas, useful for reference and alignment.
   procedure Put_Grid (Stream        : in out File_Type;
                       Width         : My_Integer;
                       Height        : My_Integer;
                       Step          : My_Integer := 50;
                       Stroke_Color  : String  := "white";
                       Stroke_Width  : String  := "0.5";
                       Opacity       : String  := "0.2"
                      ) is
      --  Draws a horizontal line at a given Y position.
      procedure Put_Horizontal_Line (Y : My_Integer) is
      begin
         Put_Line (Stream,
                     "  <line x1=""0"" y1=""" & My_Integer'Image (Y) &
                     """ x2=""" & My_Integer'Image (Width) &
                     """ y2=""" & My_Integer'Image (Y) &
                     """ stroke=""" & Stroke_Color &
                     """ stroke-width=""" & Stroke_Width &
                     """ opacity=""" & Opacity & """ />");
      end Put_Horizontal_Line;

      --  Draws a vertical line at a given X position.
      procedure Put_Vertical_Line (X : My_Integer) is
      begin
         Put_Line (Stream,
                   "  <line x1=""" & My_Integer'Image (X) &
                     """ y1=""0"" x2=""" & My_Integer'Image (X) &
                     """ y2=""" & My_Integer'Image (Height) &
                     """ stroke=""" & Stroke_Color &
                     """ stroke-width=""" & Stroke_Width &
                     """ opacity=""" & Opacity & """ />");
      end Put_Vertical_Line;
   begin
      for X in 0 .. Width / Step loop
         Put_Vertical_Line (X * Step);
      end loop;

      for Y in 0 .. Height / Step loop
         Put_Horizontal_Line (Y * Step);
      end loop;
   end Put_Grid;

   --  Puts coordinates to a single SVG path string ("d" attribute).
   procedure Put_Path (Stream : File_Type; Points : Coordinate_Array) is
   begin
      Put (Stream, "M "); --  Moves the pen without drawing.
      for J in Points'Range loop
         declare
            Coord_Text : constant String := Coordinate'Image (Points (J));
         begin
            Put (Stream, Coord_Text);
            if J < Points'Last then
               Put (Stream, " L "); --  Draws a line.
            end if;
         end;
      end loop;
   end Put_Path;

   --  Generates and emits a rosetta path element animated in rotation.
   procedure Put_Rosetta (Stream               : in out File_Type;
                          Outer_Radius         : Float;
                          Inner_Radius         : Float;
                          Pen_Offset           : Float;
                          Stroke_Color         : String;
                          Duration             : String;
                          Stroke_Width         : String  := "2";
                          Center_X             : Integer := 400;
                          Center_Y             : Integer := 400;
                          Steps                : Positive := 3000
                         ) is
      --  Creates the SVG animateTransform tag.
      function Animation_Element (
                                  Duration_Str   : String
                                 ) return String
      is
         Prefix  : constant String :=
           "<animateTransform ";
         Content : constant String :=
           "attributeName=""transform"" " &
           "attributeType=""XML"" " &
           "type=""rotate"" " &
           "from=""0"" to=""360"" " &
           "dur=""" & Duration_Str & """ " &
           "repeatCount=""indefinite"" />";
      begin
         return Prefix & Content;
      end Animation_Element;

      --  Defines the curve and compute its path.
      Curve : constant Hypotrochoid :=
        (Outer_Radius => Outer_Radius,
         Inner_Radius => Inner_Radius,
         Pen_Offset   => Pen_Offset,
         Steps        => Steps);

      Points : constant Coordinate_Array := Compute_Points (Curve);
      SVG_GroupBegin : constant String :=
        "  <g transform=""translate(" & Integer'Image (Center_X) & "," & Integer'Image (Center_Y) & ")"">" & ASCII.LF &
        "    <g transform=""rotate(0)"">" & ASCII.LF &
        "      ";

      SVG_GroupEnd : constant String := ASCII.LF &
        "      " & Animation_Element (Duration) & ASCII.LF &
        "    </g>" & ASCII.LF &
        "  </g>";

   begin
      Put_Line (Stream, SVG_GroupBegin);
      declare
         Indent  : constant String := "      ";
         Open_TagPart1 : constant String :=
           "<path d=""";
         Open_TagPart2 : constant String :=
           """ " &
           "fill=""none"" " &
           "stroke=""" & Stroke_Color & """ " &
           "stroke-width=""" & Stroke_Width & """>";
         Close_Tag : constant String := "</path>";
      begin
         Put_Line (Stream, Indent);
         Put_Line (Stream, Open_TagPart1);
         Put_Path (Stream, Points);
         Put_Line (Stream, Open_TagPart2);
         Put_Line (Stream, ASCII.LF & Indent & Close_Tag);
      end;
      Put_Line (Stream, SVG_GroupEnd);
   end Put_Rosetta;

   --  Renders a predefined set of rosettas into an SVG output.
   procedure Put_SVG_Rosettas is
      SVG_File : File_Type;
      File_Name : constant String := "rosettas.svg";
   begin
      Create (File => SVG_File, Mode => Out_File, Name => File_Name);
      Put_Header (SVG_File, Width => 800, Height => 800, Background => "#222");
      Put_Grid (SVG_File, Width => 800, Height => 800);
      Put_Rosetta (SVG_File, 150.0, 52.5, 97.5, "cyan", "6s");
      Put_Rosetta (SVG_File, 160.0, 110.0,  85.0, "gold", "14s");
      Put_Rosetta (SVG_File, 120.0,  33.0,  66.0, "orange", "4s");
      Put_Footer (SVG_File);
      Close (SVG_File);
   exception
      when others =>
         Put_Line (Standard_Error, "ERROR: Failed to generate SVG file '" & File_Name & "'.");
         if Is_Open (SVG_File) then
            Close (SVG_File);
         end if;

   end Put_SVG_Rosettas;

end Rosetta_Renderer;
