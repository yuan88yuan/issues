import fs from 'node:fs/promises';
import path from 'node:path';

export interface IssueIndex {
  id: string;
  t: string;
  s: string;
  p: string;
  pj: string;
}

export interface IssueFile {
  title: string;
  status: string;
  priority: string;
  project: string;
  description?: string;
  comments?: string[];
}

export class IssueService {
  private indexFilePath: string;
  private issuesDir: string;
  private issuesListFilePath: string;

  constructor(baseDir: string) {
    this.indexFilePath = path.join(baseDir, 'data', 'index.json');
    this.issuesDir = path.join(baseDir, 'data', 'issues');
    this.issuesListFilePath = path.join(baseDir, 'data', 'issues.md');
  }

  async getIndex(): Promise<IssueIndex[]> {
    try {
      const data = await fs.readFile(this.indexFilePath, 'utf-8');
      return JSON.parse(data);
    } catch (e) {
      return [];
    }
  }

  async updateIndex(index: IssueIndex[]): Promise<void> {
    await fs.writeFile(this.indexFilePath, JSON.stringify(index, null, 2));
  }

  async getIssueFile(id: string): Promise<IssueFile | null> {
    const filePath = path.join(this.issuesDir, `${id}.md`);
    try {
      const content = await fs.readFile(filePath, 'utf-8');
      return this.parseIssueFile(content);
    } catch (e) {
      return null;
    }
  }

  private parseIssueFile(content: string): IssueFile {
    const lines = content.split('\n');
    const issue: Partial<IssueFile> = {};
    
    for (const line of lines) {
      if (line.startsWith('title: ')) issue.title = line.replace('title: ', '').trim();
      if (line.startsWith('status: ')) issue.status = line.replace('status: ', '').trim();
      if (line.startsWith('priority: ')) issue.priority = line.replace('priority: ', '').trim();
      if (line.startsWith('project: ')) issue.project = line.replace('project: ', '').trim();
    }
    
    return issue as IssueFile;
  }

  async saveIssueFile(id: string, issue: IssueFile): Promise<void> {
    const filePath = path.join(this.issuesDir, `${id}.md`);
    const content = `title: ${issue.title}\nstatus: ${issue.status}\npriority: ${issue.priority}\nproject: ${issue.project}\n`;
    await fs.writeFile(filePath, content);
  }

  async deleteIssueFile(id: string): Promise<void> {
    const filePath = path.join(this.issuesDir, `${id}.md`);
    await fs.unlink(filePath);
  }

  async updateIssuesList(issues: IssueIndex[]): Promise<void> {
    let markdown = '| ID | Title | Status | Priority | Project |\n|---|---|---|---|---|\n';
    for (const issue of issues) {
      markdown += `| ${issue.id} | ${issue.t} | ${issue.s} | ${issue.p} | ${issue.pj} |\n`;
    }
    await fs.writeFile(this.issuesListFilePath, markdown);
  }
}
