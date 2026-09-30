# cclog: rebuild a Claude Code session transcript as markdown and read it in $EDITOR.
#
# Claude Code stores every session verbatim as JSONL under
# ~/.claude/projects/<slugified-cwd>/<session-id>.jsonl, so when terminal
# scrollback is corrupt (zellij, long responses) the conversation is still on
# disk. This renders it: your prompts and Claude's prose in full, tool calls as
# one-liners, and the cursor parked on the last thing Claude said.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jq
  ];

  programs.fish.functions = {
    cclog = {
      description = "Read a Claude Code session transcript in your editor";
      body = ''
              argparse --name=cclog \
                  h/help a/all t/thinking r/results 'n/number=' 's/session=' 'o/output=' \
                  -- $argv
              or return 1

              if set -q _flag_help
                  echo 'usage: cclog [options]'
                  echo
                  echo '  -a, --all         list sessions from every project, not just this directory'
                  echo '  -s, --session ID  render this session id (or a unique part of it), skip the picker'
                  echo '  -n, --number N    only the last N exchanges'
                  echo '  -t, --thinking    include the model thinking blocks'
                  echo '  -r, --results     include full tool output instead of the first 6 lines'
                  echo '  -o, --output PATH write the markdown to PATH instead of opening an editor'
                  echo '  -h, --help        this text'
                  return 0
              end

              if set -q _flag_number; and not string match -qr '^[1-9][0-9]*$' -- $_flag_number
                  echo "cclog: --number wants a positive integer, got '$_flag_number'" >&2
                  return 1
              end

              set -l root $HOME/.claude/projects
              if not test -d $root
                  echo "cclog: no transcripts at $root" >&2
                  return 1
              end

              # ---- gather candidate transcripts -------------------------------------

              set -l dirs
              if set -q _flag_all
                  set dirs $root/*
              else
                  set -l slug (string replace -ra '[/._]' '-' -- $PWD)
                  if test -d $root/$slug
                      set dirs $root/$slug
                  else
                      set -q _flag_session
                      or echo "cclog: no transcripts for $PWD, falling back to every project" >&2
                      set dirs $root/*
                  end
              end

              set -l files
              for d in $dirs
                  test -d $d; or continue
                  set -a files $d/*.jsonl
              end
              if test (count $files) -eq 0
                  echo 'cclog: no transcripts found' >&2
                  return 1
              end

              # newest first, skipping stubs that never got a message
              set -l sorted (stat -c '%Y	%n' -- $files | sort -rn | cut -f2)
              set -l picks
              for f in $sorted
                  grep -qm1 '"type":"user"' -- $f; or continue
                  set -a picks $f
                  test (count $picks) -ge 15; and break
              end
              if test (count $picks) -eq 0
                  echo 'cclog: no transcripts with any messages' >&2
                  return 1
              end

              # ---- choose one -------------------------------------------------------

              set -l chosen
              if set -q _flag_session
                  for f in $sorted
                      if string match -q "*$_flag_session*" -- (basename $f .jsonl)
                          set chosen $f
                          break
                      end
                  end
                  if test -z "$chosen"
                      echo "cclog: no session matching '$_flag_session'" >&2
                      return 1
                  end
              else if test (count $picks) -eq 1
                  set chosen $picks[1]
              else
                  set -l now (date +%s)
                  set -l rows
                  for i in (seq (count $picks))
                      set -l f $picks[$i]
                      set -l age (_cclog_age (math $now - (stat -c %Y -- $f)))
                      set -l count (grep -c '"type":"assistant"' -- $f)
                      set -l title (string sub -l 50 -- (_cclog_title $f))
                      set -l where ""
                      set -q _flag_all; and set where '  '(_cclog_cwd $f)
                      set -a rows (printf '%3d  %-9s  %-50s  %5s msgs%s' $i $age $title $count $where)
                  end

                  if command -q fzf
                      set -l line (printf '%s\n' $rows | fzf --no-sort --height=40% --reverse \
                          --prompt='session > ' --header='pick a Claude Code session')
                      or return 1
                      set chosen $picks[(string trim -- (string sub -l 3 -- $line))]
                  else
                      printf '%s\n' $rows
                      echo
                      read -P 'session [1]: ' -l reply
                      test -z "$reply"; and set reply 1
                      if not string match -qr '^[0-9]+$' -- $reply; or test $reply -gt (count $picks); or test $reply -lt 1
                          echo 'cclog: not a listed session' >&2
                          return 1
                      end
                      set chosen $picks[$reply]
                  end
              end

              # ---- render -----------------------------------------------------------

              set -l id (basename $chosen .jsonl)
              set -l out $_flag_output
              test -z "$out"; and set out /tmp/cclog-(string sub -l 8 -- $id).md

              # --number keeps only the tail of the file, starting at the Nth-from-last
              # thing you actually typed
              set -l src $chosen
              set -l scratch
              if set -q _flag_number
                  set -l starts (jq -r 'select(.type == "user"
                      and (.promptSource == "typed" or .promptSource == "suggestion_accepted"))
                      | input_line_number' -- $chosen)
                  if test (count $starts) -gt $_flag_number
                      set scratch (mktemp -t cclog-slice-XXXXXX.jsonl)
                      tail -n +$starts[(math (count $starts) - $_flag_number + 1)] -- $chosen >$scratch
                      set src $scratch
                  end
              end

              begin
                  set -l head "`$id` · "(_cclog_cwd $chosen)
                  set -q _flag_number; and set head "$head · last $_flag_number exchanges"
                  echo "# "(_cclog_title $chosen)
                  echo
                  echo $head

                  jq -r \
                      --argjson thinking (set -q _flag_thinking; and echo true; or echo false) \
                      --argjson fullresults (set -q _flag_results; and echo true; or echo false) \
                      (_cclog_renderer | string collect) -- $src
              end >$out

              test -n "$scratch"; and rm -f $scratch

              if set -q _flag_output
                  echo "wrote $out"
                  return 0
              end

              # park the cursor on the last thing Claude said, which is what you scrolled back for
              set -l line (grep -n '^# ⏺ Claude' -- $out | tail -n1 | cut -d: -f1)
              test -z "$line"; and set line 1

              set -l editor $EDITOR
              test -z "$editor"; and set editor hx
              set -l cmd (string split ' ' -- $editor)

              echo $out
              switch (basename $cmd[1])
                  case hx helix
                      $cmd $out:$line
                  case vim nvim vi
                      $cmd +$line $out
                  case '*'
                      $cmd $out
              end
      '';
    };

    _cclog_age = {
      description = "Format a second count as a rough age";
      argumentNames = [ "secs" ];
      body = ''
              if test $secs -lt 60
                  echo 'just now'
              else if test $secs -lt 3600
                  echo (math -s0 $secs / 60)'m ago'
              else if test $secs -lt 86400
                  echo (math -s0 $secs / 3600)'h ago'
              else
                  echo (math -s0 $secs / 86400)'d ago'
              end
      '';
    };

    _cclog_title = {
      description = "Title of a Claude Code transcript";
      argumentNames = [ "file" ];
      body = ''
              # the title record is rewritten every turn, so the last one is current
              set -l t (tail -n 300 -- $file | jq -r 'select(.type == "ai-title") | .aiTitle' 2>/dev/null | tail -n1)
              if test -z "$t"
                  set t (head -n 60 -- $file | jq -r 'select(.type == "user" and .promptSource == "typed")
                      | .message.content | if type == "string" then . else "" end' 2>/dev/null | head -n1)
                  set t (string sub -l 70 -- (string replace -a \n ' ' -- "$t"))
              end
              test -z "$t"; and set t '(untitled)'
              echo $t
      '';
    };

    _cclog_cwd = {
      description = "Working directory a Claude Code transcript was recorded in";
      argumentNames = [ "file" ];
      body = ''
              set -l c (head -n 40 -- $file | jq -r 'select(.cwd) | .cwd' 2>/dev/null | head -n1)
              test -z "$c"; and set c (basename (dirname $file))
              echo $c
      '';
    };

    _cclog_renderer = {
      description = "jq program that turns a transcript into markdown";
      body = ''
              echo '
          def clip($n): if (length > $n) then (.[0:$n] + "…") else . end;
          def flat: gsub("[\r\n]+"; " ⏎ ");
          def hhmm:
            (.timestamp // "")
            | if . == "" then "--:--"
              else (sub("\\\\.[0-9]+Z$"; "Z") | fromdateiso8601? // null)
                   | if . == null then "--:--" else strflocaltime("%H:%M") end
              end;

          def toolline:
            .name as $n
            | (.input.description // .input.file_path // .input.command // .input.pattern
               // .input.prompt // .input.query // .input.url // .input.skill // "")
            | (if type == "string" then . else tostring end)
            | flat | clip(110)
            | if . == "" then "  ⏺ \($n)" else "  ⏺ \($n) — \(.)" end;

          def resultlines:
            (if (.content | type) == "string" then .content
             elif (.content | type) == "array" then ([.content[]? | (.text // .type // "")] | join("\n"))
             else (.content | tostring) end) as $txt
            | (if (.is_error // false) then "  ⤷ error" else "  ⤷" end) as $tag
            | ($txt | rtrimstr("\n") | split("\n")) as $lines
            | if ($txt | length) == 0 then ["  ⤷ (no output)"]
              elif $fullresults or ($lines | length) <= 6
                then [$tag] + [$lines[] | "    │ " + .]
              else [$tag] + [$lines[0:6][] | "    │ " + .]
                   + ["    │ … \($lines | length - 6) more lines"]
              end;

          def userblocks:
            ([.message.content[]? | select(.type == "text") | .text] | join("\n\n")) as $said
            | ([.message.content[]? | select(.type == "tool_result")] | map(resultlines) | add // []) as $res
            | (if ($said | length) > 0 then ["", "# ⏵ You · \(hhmm)", "", $said] else [] end) + $res;

          def assistantblocks:
            ([.message.content[]? | select(.type == "text") | .text] | join("\n\n")) as $said
            | ([.message.content[]? | select(.type == "thinking") | .thinking]) as $thought
            | ([.message.content[]? | select(.type == "tool_use")] | map(toolline)) as $tools
            | (if $thinking and ($thought | length) > 0
               then ["", "# ⋯ thinking · \(hhmm)", ""]
                    + ($thought | map(split("\n") | map("> " + .) | join("\n")))
               else [] end)
            + (if ($said | length) > 0 then ["", "# ⏺ Claude · \(hhmm)", "", $said] else [] end)
            + (if ($tools | length) > 0 then [""] + $tools else [] end);

          select(.type == "user" or .type == "assistant")
          | select((.isMeta // false) | not)
          | if .type == "assistant" then assistantblocks
            elif (.message.content | type) != "string" then userblocks
            else
              .message.content as $c
              | if ($c | test("^<(task-notification|system-reminder|local-command-std|bash-input|bash-std)")) then []
                elif (.isCompactSummary // false) then ["", "# ⟲ conversation compacted · \(hhmm)", "", $c]
                elif ($c | test("<command-name>")) then
                  ["", "# ⏵ You · \(hhmm)", "", ($c | capture("<command-name>(?<n>[^<]*)</command-name>").n)]
                else ["", "# ⏵ You · \(hhmm)", "", $c]
                end
            end
          | .[]
          '
      '';
    };
  };
}
